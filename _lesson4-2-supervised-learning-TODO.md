# Supervised Learning Chapter - Improvements and Extensions

## Part 1: General Improvements to Current Chapter

### Critical Issues to Address

#### 1. Limited Evaluation Metrics

**Problem:**
The chapter only uses overall accuracy to evaluate the model. This is problematic because:
- It doesn't reveal per-class performance (which class is performing poorly?)
- It's misleading with imbalanced datasets
- You already have the confusion matrix but don't derive useful metrics from it

**Recommendation:**
Add at least:
- Per-class precision/recall (or Producer's/User's accuracy in RS terminology)
- F1-scores per class
- Show students how to interpret the confusion matrix more thoroughly

**Example Code to Add:**
```r
# Per-class accuracy (Producer's accuracy)
# How many of the actual class X pixels were correctly identified?
producer_acc <- diag(confusion_matrix) / colSums(confusion_matrix)
names(producer_acc) <- colnames(confusion_matrix)

# Per-class precision (User's accuracy)
# Of all pixels classified as X, how many were actually X?
user_acc <- diag(confusion_matrix) / rowSums(confusion_matrix)
names(user_acc) <- rownames(confusion_matrix)

# Display results
kable(data.frame(
  Class = names(producer_acc),
  `Producer's Accuracy` = round(producer_acc, 3),
  `User's Accuracy` = round(user_acc, 3),
  `F1-Score` = round(2 * (producer_acc * user_acc) / (producer_acc + user_acc), 3)
))
```

#### 2. No Discussion of Class Imbalance

**Problem:**
You never check or discuss whether the classes are balanced in your training data. This is crucial because:
- Imbalanced classes can lead to biased models
- Overall accuracy becomes even more misleading with imbalance
- Students won't know this is something to check

**Recommendation:**
Add a simple visualization showing the distribution of classes in your labeled data.

**Example Code to Add:**
```r
# Check class distribution
class_counts <- labelled_data |>
  st_drop_geometry() |>
  count(class)

ggplot(class_counts, aes(x = class, y = n, fill = class)) +
  geom_col() +
  geom_text(aes(label = n), vjust = -0.5) +
  labs(title = "Distribution of Labeled Points per Class",
       x = "Class", y = "Count") +
  theme_minimal()
```

Add discussion:
- Are the classes balanced?
- If not, how might this affect the model?
- Strategies to handle imbalance (weighted sampling, SMOTE, class weights)

#### 3. No Hyperparameter Tuning Discussion

**Problem:**
CART models have critical hyperparameters that control overfitting:
- `cp` (complexity parameter)
- `minsplit`, `minbucket`
- `maxdepth`

The default parameters might not be optimal.

**Recommendation:**
Add a section discussing hyperparameters:

```r
# Show default parameters
cart_model$control

# Example: Train with different complexity parameters
cp_values <- c(0.001, 0.01, 0.05, 0.1)
models <- lapply(cp_values, function(cp) {
  rpart(class~., data = data_train2, method = "class",
        control = rpart.control(cp = cp))
})

# Compare performance
# (students can evaluate on test set)
```

Discuss:
- What `cp` controls (tree complexity)
- Trade-off between model complexity and generalization
- How to select appropriate values (cross-validation)

#### 4. No Validation Set

**Problem:**
You only have train/test split. Testing data should only be used once at the end.

**Recommendation:**
While acceptable for teaching, mention:
- Why a validation set matters (hyperparameter tuning)
- That testing data should only be used once at the end
- Cross-validation as a better alternative

Add a note like:
> **Note on Model Validation:** In a production setting, we would split our data into three sets: training (60%), validation (20%), and testing (20%). The validation set is used to tune hyperparameters, while the test set is only used once for final evaluation. Alternatively, we could use k-fold cross-validation on the training data.

#### 5. No Overfitting Discussion

**Problem:**
You never discuss whether the model is overfitting, how to detect it, or why it matters.

**Recommendation:**
Add a section comparing train and test performance:

```r
# Evaluate on training data
train_pred <- predict(cart_model, data_train2, type = "class")
train_accuracy <- mean(train_pred == data_train2$class)

# Compare with test accuracy
cat("Training accuracy:", round(train_accuracy, 3), "\n")
cat("Testing accuracy:", round(test_accuracy, 3), "\n")

# Discuss:
# - If train >> test: overfitting
# - If both low: underfitting
# - Goal: balance bias and variance
```

### Minor Issues

#### 6. Typo (line 255)
"haev" → "have"

#### 7. Missing Context on Model Selection

**Recommendation:**
Add a brief section:
- Why CART vs other algorithms?
- When is CART appropriate? (interpretability, non-linear boundaries, no feature scaling needed)
- What are its limitations? (high variance, not always best performance)
- Alternatives: Random Forest, SVM, Neural Networks

## Part 2: Using Complete Polygon Coverage

### Scenario
Someone has digitized the entire region into different classes as consecutive, non-overlapping polygons. This changes the approach significantly.

### Key Differences from Point-based Labeling

1. **Complete spatial coverage** - no unlabeled areas
2. **Much more training data available** - millions of pixels
3. **Spatial autocorrelation becomes critical** - nearby pixels are highly similar
4. **Polygon boundaries** may have mixed pixels or uncertainty
5. **Class imbalance** likely pronounced (large vs small landcover types)

### Recommended Workflow

#### 1. Rasterize the Polygons

```r
# Load polygon data
landcover_polygons <- read_sf("data-large/ces/landcover_polygons.gpkg")

# Rasterize to match your imagery resolution
landcover_raster <- rasterize(landcover_polygons, ces1961, field = "class")

# Visualize
plot(landcover_raster)
```

#### 2. Spatial Sampling Strategy (CRITICAL!)

With complete coverage, spatial autocorrelation becomes even more important. **Never randomly sample pixels across the entire region!**

##### Option A: Spatial Block Cross-Validation (Recommended)

```r
library(blockCV)

# Create spatial blocks for train/test split
spatial_blocks <- cv_spatial(
  x = landcover_polygons,
  k = 5,  # 5-fold CV
  hexagon = FALSE,  # rectangular blocks
  size = 500  # block size in meters (adjust based on your study area)
)

# Visualize the blocks
plot(spatial_blocks)

# Use some blocks for training, others for testing
landcover_polygons <- landcover_polygons |>
  mutate(fold = spatial_blocks$folds_ids)

train_polygons <- landcover_polygons |> filter(fold != 1)
test_polygons <- landcover_polygons |> filter(fold == 1)
```

##### Option B: Leave-Polygon-Out

```r
# Randomly assign entire polygons to train/test
# This ensures geographic separation
set.seed(123)
landcover_polygons <- landcover_polygons |>
  mutate(
    polygon_id = row_number(),
    fold = sample(rep(1:5, length.out = n()))
  )

train_polygons <- landcover_polygons |> filter(fold != 1)
test_polygons <- landcover_polygons |> filter(fold == 1)

# Visualize the split
tm_shape(train_polygons) + tm_fill(col = "blue") +
  tm_shape(test_polygons) + tm_fill(col = "red")
```

##### Option C: Buffer-Based Exclusion

```r
# Create a buffer around test areas to exclude from training
# This prevents training on pixels close to test pixels

set.seed(123)
test_sample <- landcover_polygons |>
  slice_sample(prop = 0.2)

# Create 50m buffer around test polygons
test_buffer <- st_buffer(test_sample, dist = 50)

# Remove training polygons that intersect with buffer
train_polygons <- landcover_polygons |>
  st_difference(st_union(test_buffer))
```

#### 3. Sampling Within Polygons

You likely don't want to use EVERY pixel (computationally expensive). Instead, sample strategically:

```r
# Strategy 1: Fixed number of points per polygon
sample_points_per_polygon <- function(polygons, n_per_polygon = 50) {
  polygons |>
    rowwise() |>
    mutate(
      # Sample points within each polygon
      sampled_points = list(st_sample(geometry, size = n_per_polygon))
    ) |>
    select(class, sampled_points) |>
    st_set_geometry("sampled_points")
}

# Strategy 2: Stratified by class (equal samples per class)
sample_points_by_class <- function(polygons, n_per_class = 500) {
  polygons |>
    group_by(class) |>
    slice_sample(n = n_per_class) |>
    rowwise() |>
    mutate(point = list(st_sample(geometry, size = 1))) |>
    ungroup() |>
    select(class) |>
    st_set_geometry("point")
}

# Strategy 3: Proportional to polygon area
sample_points_proportional <- function(polygons, density = 0.01) {
  # density = points per square meter
  polygons |>
    rowwise() |>
    mutate(
      n_samples = max(1, round(as.numeric(st_area(geometry)) * density)),
      sampled_points = list(st_sample(geometry, size = n_samples))
    )
}

# Apply sampling
train_samples <- sample_points_by_class(train_polygons, n_per_class = 500)
test_samples <- sample_points_by_class(test_polygons, n_per_class = 200)
```

#### 4. Avoid Polygon Edges

Edges might have mixed pixels or be less reliable:

```r
# Negative buffer to stay away from edges (e.g., 5 meters inward)
polygons_inner <- st_buffer(landcover_polygons, dist = -5)

# Then sample from these inner polygons
train_samples <- sample_points_by_class(
  st_intersection(train_polygons, polygons_inner),
  n_per_class = 500
)
```

#### 5. Feature Extraction

Same as before, but now from sampled points:

```r
# Extract features at sample points
train_features <- terra::extract(ces1961, train_samples, ID = FALSE)
test_features <- terra::extract(ces1961, test_samples, ID = FALSE)

# Combine with class labels
data_train <- cbind(train_samples, train_features) |>
  st_drop_geometry()

data_test <- cbind(test_samples, test_features) |>
  st_drop_geometry()
```

#### 6. Train and Evaluate as Before

```r
# Train model
cart_model <- rpart(class~., data = data_train, method = "class")

# Predict on test samples
test_pred <- predict(cart_model, data_test, type = "class")

# Confusion matrix
confusion_matrix <- table(Predicted = test_pred, Actual = data_test$class)
```

### Complete Example Workflow

```r
# 1. Load polygon data
landcover_poly <- read_sf("data-large/ces/complete_landcover.gpkg")

# 2. Spatial block assignment
library(blockCV)
blocks <- cv_spatial(landcover_poly, k = 5, size = 300)

# 3. Split into train/test by blocks
landcover_poly$fold <- blocks$folds_ids
train_polys <- landcover_poly |> filter(fold != 1)
test_polys <- landcover_poly |> filter(fold == 1)

# 4. Buffer inward to avoid edges
train_polys_inner <- st_buffer(train_polys, dist = -3) |>
  filter(st_is_valid(geometry))  # Remove invalid geometries
test_polys_inner <- st_buffer(test_polys, dist = -3) |>
  filter(st_is_valid(geometry))

# 5. Sample points (stratified by class)
set.seed(123)
train_points <- train_polys_inner |>
  group_by(class) |>
  slice_sample(n = 200) |>  # 200 polygons per class
  rowwise() |>
  mutate(point = list(st_sample(geometry, size = 1))) |>
  ungroup() |>
  select(class) |>
  st_set_geometry("point") |>
  st_as_sf()

test_points <- test_polys_inner |>
  group_by(class) |>
  slice_sample(n = 100) |>  # 100 polygons per class
  rowwise() |>
  mutate(point = list(st_sample(geometry, size = 1))) |>
  ungroup() |>
  select(class) |>
  st_set_geometry("point") |>
  st_as_sf()

# 6. Extract features
train_features <- terra::extract(ces1961, train_points, ID = FALSE)
data_train <- cbind(train_points, train_features) |>
  st_drop_geometry()

test_features <- terra::extract(ces1961, test_points, ID = FALSE)
data_test <- cbind(test_points, test_features) |>
  st_drop_geometry()

# 7. Train model
cart_model <- rpart(class~., data = data_train, method = "class")

# 8. Evaluate
test_pred <- predict(cart_model, data_test, type = "class")
confusion_matrix <- table(Predicted = test_pred, Actual = data_test$class)
accuracy <- sum(diag(confusion_matrix)) / sum(confusion_matrix)
```

### Critical Considerations

#### ⚠️ Spatial Autocorrelation
- **Never randomly sample pixels across the entire region**
- Ensure geographic separation between train/test
- Your current lesson mentions this (@brenning2023, @schratz2021) - this is even more critical with polygon data
- Rule of thumb: test area should be at least 100-500m away from training areas (depends on spatial resolution and landscape)

#### ⚠️ Computational Efficiency
- Don't extract features for millions of pixels unless necessary
- Sample strategically (e.g., 100-1000 points per class might be sufficient)
- Start small, scale up if needed
- For very large areas, consider tiling

#### ⚠️ Class Imbalance
- Large polygons (e.g., forest) will dominate if sampled proportionally
- Use stratified sampling by class, not by area
- Consider equal samples per class or weighted sampling
- Alternatively, use class weights in the model

#### ⚠️ Edge Effects
- Pixels at polygon boundaries may be mixed/uncertain
- Consider buffering inward from edges
- Or weight samples by distance from edge
- Geolocation errors compound this issue

#### ⚠️ Polygon Quality
- Digitization errors may exist
- Some polygons may be very small (after buffering)
- Always validate geometries: `st_is_valid()`
- Filter out tiny polygons that won't provide reliable samples

### What to Emphasize in Teaching

1. **Spatial CV is non-negotiable** with complete coverage
2. **Sample strategically** - don't use all pixels
3. **Balance your classes** regardless of polygon areas
4. **Visualize your train/test split** geographically to ensure separation
5. **Consider edge uncertainty** in polygons
6. **Always check class distribution** in both train and test sets
7. **Computational trade-offs**: more samples ≠ better model (diminishing returns)

### Extension: Using Polygons for Validation Only

An alternative approach is to:
1. Train using your existing point-based labels
2. Use the polygon data to create a separate, spatially-independent validation set
3. This allows you to assess how well your model generalizes to completely new areas

```r
# Train on points (as in original lesson)
cart_model <- rpart(class~., data = data_train_points, method = "class")

# Validate on polygon-derived samples (from a different area)
validation_samples <- sample_from_polygons(landcover_poly, n = 1000)
validation_features <- terra::extract(ces1961, validation_samples, ID = FALSE)
validation_pred <- predict(cart_model, validation_features, type = "class")

# This tells you how well your model generalizes spatially
```

### References

- Brenning, A. (2023). Spatial cross-validation and bootstrap for the assessment of prediction rules in remote sensing. *IEEE Journal of Selected Topics in Applied Earth Observations and Remote Sensing*.
- Schratz, P., et al. (2021). Hyperparameter tuning and performance assessment of statistical and machine-learning algorithms using spatial data. *Ecological Modelling*.
- Meyer, H., & Pebesma, E. (2021). Predicting into unknown space? Estimating the area of applicability of spatial prediction models. *Methods in Ecology and Evolution*.
