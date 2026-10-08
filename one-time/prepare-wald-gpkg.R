
library(sf)

# Read the forest polygon for 1961
forest_poly <- read_sf("data/ces.gpkg", layer = "Wald_1961")
# Create a bounding box for the study area
study_area <- st_minimum_rotated_rectangle(forest_poly)


# Create non-forest polygon (study area minus forest)
# Note: st_difference can be slow for complex geometries
non_forest_poly <- st_difference(study_area, st_union(forest_poly))
non_forest_poly$area <- as.numeric(st_area(non_forest_poly))

non_forest_poly$class <- "Non-Forest"


forest_poly$class <- "Forest"


forest_1961 <- bind_rows(forest_poly, non_forest_poly)

st_write(forest_1961, "data/ces_polygons.gpkg")

