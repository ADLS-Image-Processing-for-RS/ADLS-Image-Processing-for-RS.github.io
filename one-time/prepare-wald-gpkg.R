

library(sf)


wald1961 <- st_read("data/ces.gpkg", "Wald_1961")

study_area <- st_minimum_rotated_rectangle(wald1961)

study_area$area <- NULL

nicht_wald1961 <- st_difference(st_buffer(study_area, -5), st_union(wald1961))

wald1961
nicht_wald1961$area <- as.numeric(st_area(nicht_wald1961))
nicht_wald1961$class <- "Non-forest"
wald1961$class <- "Forest"



ces_polygons <- rbind(wald1961, nicht_wald1961)

st_write(ces_polygons, "data/ces_polygons.gpkg", append = FALSE)
st_write(study_area, "data/ces_polygons.gpkg", layer = "study_area")


