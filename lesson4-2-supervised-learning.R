 ------------------------------------------------------------------------------------------
library(terra)
library(sf)
library(dplyr)
library(tmap)

ces1961 <- rast("data-large/ces/1961.tif")
ces1961 <- ces1961/255 # normalize to [0,1]
names(ces1961) <- "luminosity"


## ------------------------------------------------------------------------------------------
plot(ces1961, col = grey.colors(255))

ces_grey <- tm_shape(ces1961) + 
  tm_raster(col.scale = tm_scale_continuous(values = "-brewer.greys"))

tmap_save(ces_grey, "img/ces-grey.png",height = 20, width = 20, units = "cm")


## ------------------------------------------------------------------------------------------
# Load polygons
ces_polygons <- read_sf("data/ces_polygons.gpkg", "ces_polygons")
study_area <- read_sf("data/ces_polygons.gpkg", "study_area")


ces_poly <- tm_shape(ces_polygons) +
  tm_polygons(fill = "class") +
  tm_shape(study_area) +
  tm_borders(col = "red")

tmap_save(ces_poly, "img/ces-poly.png",height = 20, width = 20, units = "cm")


# Generate spatially distributed samples
set.seed(42)
sample_points <- st_sample(ces_polygons, 1000) |>
  st_sf()
st_geometry(sample_points) <- "geom"

labelled_data <- st_join(sample_points, ces_polygons) |>
  select(-jahr)

labelled_data$class <- factor(labelled_data$class)


## ------------------------------------------------------------------------------------------
#| echo: false
tmap_mode("plot")


## ------------------------------------------------------------------------------------------
#| echo: false
#| fig-cap: Sample points from forest (green) and non-forest (orange) polygons

ces_samples <- tm_shape(ces1961) +
  tm_raster(col.scale = tm_scale_continuous(values = "-brewer.greys"), col.legend = tm_legend_hide()) +
  tm_shape(labelled_data) +
  tm_dots(
    fill = "class",
    fill.scale = tm_scale_categorical(values = c("Forest" = "palegreen4", "Non-forest" = "orange"))) +
  tm_layout(legend.outside = TRUE) +
  tm_shape(study_area) + tm_borders()


tmap_save(ces_samples, "img/ces-samples.png",height = 20, width = 20, units = "cm")


## ------------------------------------------------------------------------------------------
labelled_data <- labelled_data |>
  group_by(class) |>
  mutate(
    i = sample(seq_len(n())),
    train = i <= n()*0.7
  )

data_train <- labelled_data |> filter(train) |> select(-c(i,train))
data_test <- labelled_data |> filter(!train) |> select(-c(i,train))


## ------------------------------------------------------------------------------------------
# Extract pixel values at training points
train_features <- terra::extract(ces1961, data_train, ID = FALSE)

data_train2 <- cbind(data_train[,"class"], train_features) |>
  st_drop_geometry() |> 
  as_tibble()

save(data_train2, file = "data/data_train.Rda")


head(data_train2)


## ------------------------------------------------------------------------------------------
library(rpart)
cart_model <- rpart(class~luminosity, data = data_train2)

save(cart_model, file = "data/cart_model.Rda")


## ------------------------------------------------------------------------------------------
#| label: fig-cart-basic
#| fig-cap: Decision tree for single-band classification

library(rpart.plot)
rpart.plot(cart_model)


## ------------------------------------------------------------------------------------------
# Predict probability per class for all pixels
ces1961_predict <- predict(ces1961, cart_model)

# Get highest probability class
ces1961_predict2 <- which.max(ces1961_predict)

# Assign class labels
classes <- levels(data_train2$class)
classes_df <- data.frame(ID = seq_along(classes), class = classes)
levels(ces1961_predict2) <- classes_df


## ------------------------------------------------------------------------------------------
#| fig-cap: Classification result - single band approach

ces_predict <- tm_shape(ces1961_predict2) +
  tm_raster(palette = c("Forest" = "palegreen4", "Non-forest" = "orange")) +
  tm_layout(legend.outside = TRUE)


tmap_save(ces_predict, "img/ces-predict.png",height = 20, width = 20, units = "cm")


## ------------------------------------------------------------------------------------------
#| output: false
test_features <- terra::extract(ces1961_predict2, data_test, ID = FALSE)

confusion_matrix <- cbind(data_test, test_features) |>
  st_drop_geometry() |>
  transmute(predicted = class.1, actual = class) |>
  table()

save(confusion_matrix, file = "data/confusion_matrix.Rda")

## ------------------------------------------------------------------------------------------
#| echo: false
#| label: tbl-confusion-matrix-basic
#| tbl-cap: Confusion matrix for single-band classification

library(tidyr)
library(kableExtra)

confusion_matrix2 <- confusion_matrix |>
  as_tibble() |>
  pivot_wider(names_from = actual, values_from = n, values_fill = 0)

highlight_diagonal <- \(kable_table, diag_cols, color = "red", default_color = "white") {
  purrr::reduce(seq_along(diag_cols), \(tbl, i) {
    tbl |> column_spec(diag_cols[i], background = ifelse(seq_along(diag_cols) == i, color, default_color))
  }, .init = kable_table)
}

col_names <- colnames(confusion_matrix2)
col_names[1] <- ""

kable(confusion_matrix2, col.names = col_names) |>
  kable_styling(full_width = FALSE) |>
  column_spec(1, bold = TRUE) |>
  highlight_diagonal(2:3) |>
  add_header_above(c(" " = 1, "Actual" = 2))


## ------------------------------------------------------------------------------------------
#| echo: false
confusion_matrix3 <- as.matrix(confusion_matrix2[,-1])
correct <- diag(confusion_matrix3)
tot <- colSums(confusion_matrix3)
acc_basic <- sum(correct)/sum(tot)
acc_basic_str <- format(acc_basic, digits = 2)

save(acc_basic_str, acc_multi_str,confusion_matrix2_multi,  file = "data/vals.Rda")


## ------------------------------------------------------------------------------------------
#| label: fig-zoom-problem
#| fig-cap: At pixel level, can you distinguish forest from non-forest? Spatial context is essential.

xmin <- 2706200
xmax <- xmin+100
ymin <- 1143600
ymax <- ymin+100
e <- ext(xmin, xmax, ymin, ymax)

ces1961_crop <- crop(ces1961, e)

ces_crop <- tm_shape(ces1961_crop) + 
  tm_raster(col.scale = tm_scale_continuous(values = "-brewer.greys"))

tmap_save(ces_crop, "img/ces-crop.png",height = 20, width = 20, units = "cm")


## ------------------------------------------------------------------------------------------
# Define 5x5 neighborhood
n <- 5
focal_window <- matrix(rep(1, n^2), ncol = n)

# Calculate standard deviation in each neighborhood
ces1961_focal_sd <- focal(ces1961, focal_window, fun = sd, fillvalue = 0)


## ------------------------------------------------------------------------------------------
#| layout-nrow: 1
#| label: fig-focal-comparison
#| fig-cap:
#|   - Original raster
#|   - After focal SD filter (shows texture/variation)
#| echo: false

ces1961_focal_sd_crop <- crop(ces1961_focal_sd, e)


ces_focal_crop <- tm_shape(crop(ces1961_focal_sd, e)) + 
  tm_raster(col.scale = tm_scale_continuous(values = "-brewer.greys"))


tmap_save(ces_focal_crop, "img/ces-focal-crop.png",height = 20, width = 20, units = "cm")

## ------------------------------------------------------------------------------------------
minmax_normalization <- function(x){
  minmax_vals <- minmax(x)[,1]
  (x - minmax_vals[1]) / (minmax_vals[2] - minmax_vals[1])
}

ces1961_focal_sd <- minmax_normalization(ces1961_focal_sd)

# Combine original and focal features
ces_multi <- c(ces1961, ces1961_focal_sd)
names(ces_multi) <- c("luminosity", "focal_sd")


## ------------------------------------------------------------------------------------------
# Extract both features
train_features_multi <- terra::extract(ces_multi, data_train, ID = FALSE)
data_train2_multi <- cbind(data_train, train_features_multi) |>
  st_drop_geometry() |> 
  select(-area)

# Train model
cart_model_multi <- rpart(class~., data = data_train2_multi)

save(cart_model_multi, file = "data/cart_model_multi.Rda")

## ------------------------------------------------------------------------------------------
#| label: fig-cart-multi
#| fig-cap: Decision tree now uses both luminosity and spatial texture

library(rpart.plot)
rpart.plot(cart_model_multi, type = 3)



## ------------------------------------------------------------------------------------------
# Predict on raster
ces1961_predict_multi <- predict(ces_multi, cart_model_multi)
ces1961_predict2_multi <- which.max(ces1961_predict_multi)
levels(ces1961_predict2_multi) <- classes_df

# Evaluate
test_features_multi <- terra::extract(ces1961_predict2_multi, data_test, ID = FALSE)
confusion_matrix_multi <- cbind(data_test, test_features_multi) |>
  st_drop_geometry() |>
  transmute(predicted = class.1, actual = class) |>
  table()


## ------------------------------------------------------------------------------------------
#| echo: false
#| label: tbl-confusion-matrix-multi
#| tbl-cap: Confusion matrix with spatial features

confusion_matrix2_multi <- confusion_matrix_multi |>
  as_tibble() |>
  pivot_wider(names_from = actual, values_from = n, values_fill = 0)

col_names_multi <- colnames(confusion_matrix2_multi)
col_names_multi[1] <- ""

kable(confusion_matrix2_multi, col.names = col_names_multi) |>
  kable_styling(full_width = FALSE) |>
  column_spec(1, bold = TRUE) |>
  highlight_diagonal(2:3) |>
  add_header_above(c(" " = 1, "Actual" = 2))


## ------------------------------------------------------------------------------------------
#| echo: false
confusion_matrix3_multi <- as.matrix(confusion_matrix2_multi[,-1])
correct_multi <- diag(confusion_matrix3_multi)
tot_multi <- colSums(confusion_matrix3_multi)
acc_multi <- sum(correct_multi)/sum(tot_multi)
acc_multi_str <- format(acc_multi, digits = 2)


## ------------------------------------------------------------------------------------------
years <- c(1961, 1971, 1977, 1983, 1989, 1995)

ces_all <- lapply(years, \(year) {
  r <- rast(paste0("data-large/ces/", year, ".tif"))
  r <- r / 255
  names(r) <- "luminosity"
  return(r)
})

names(ces_all) <- years


## ------------------------------------------------------------------------------------------
# Apply focal operation to all years
ces_all_focal <- lapply(ces_all, \(raster) {
  focal_sd <- focal(raster, focal_window, fun = sd, fillvalue = 0)
  focal_sd <- minmax_normalization(focal_sd)
  multi <- c(raster, focal_sd)
  names(multi) <- c("luminosity", "focal_sd")
  return(multi)
})

# Predict for all years
predictions_all <- lapply(ces_all_focal, \(raster) {
  pred_prob <- predict(raster, cart_model_multi)
  pred_class <- which.max(pred_prob)
  levels(pred_class) <- classes_df
  return(pred_class)
})

names(predictions_all) <- years


## ------------------------------------------------------------------------------------------
#| fig-width: 12
#| fig-height: 8
#| fig-cap: Forest classification across time (model trained on 1961 applied to all years)

library(patchwork)

plot_comparison <- function(year) {
  p1 <- tm_shape(ces_all[[as.character(year)]]) +
    tm_raster(palette = "-brewer.greys", legend.show = FALSE) +
    tm_layout(main.title = paste(year, "- Original"),
              main.title.size = 1.2,
              main.title.position = "center")

  p2 <- tm_shape(predictions_all[[as.character(year)]]) +
    tm_raster(palette = c("Forest" = "palegreen4", "Non-forest" = "orange"),
              title = "Class") +
    tm_layout(main.title = paste(year, "- Classification"),
              main.title.size = 1.2,
              main.title.position = "center",
              legend.outside = TRUE)

  return(tmap_arrange(p1, p2, ncol = 2))
}

tmap_mode("plot")

for (year in years) {
  print(plot_comparison(year))
}


## ------------------------------------------------------------------------------------------
#| fig-cap: Forest area change (1961-1995)

forest_area <- sapply(predictions_all, \(pred) {
  freq_table <- freq(pred)
  forest_pixels <- freq_table[freq_table$class == "Forest", "count"]
  forest_ha <- forest_pixels / 10000
  return(forest_ha)
})

forest_df <- data.frame(
  year = as.numeric(names(forest_area)),
  forest_ha = as.numeric(forest_area)
)

library(ggplot2)
ggplot(forest_df, aes(x = year, y = forest_ha)) +
  geom_line(color = "palegreen4", linewidth = 1.5) +
  geom_point(color = "palegreen4", size = 3) +
  labs(x = "Year", y = "Forest area (hectares)",
       title = "Forest cover change (1961-1995)") +
  theme_minimal() +
  theme(text = element_text(size = 12))


## ------------------------------------------------------------------------------------------
#| echo: false

save.image(file = "data-out/workspace.Rdata")

