## prepare_ces_data.R
## Prepares CES data for lesson 4 (supervised classification).
##
## Inputs:
##   data/ces.gpkg                            – Wald_1961/1999/2021 polys + Ces study area
##   data-large/ces/swissimage-dop10_2021_*.tif  – 4 RGB tiles (2 m, EPSG:2056)
##   data-large/ces/swissimage-dop10_2024_*.tif  – 4 RGB tiles (2 m, EPSG:2056)
##
## Outputs:
##   data/ces_polygons.gpkg               – adds layers ces_polygons_1999, ces_polygons_2021
##                                          (same structure as existing ces_polygons layer)
##   data-large/ces/2021_rgb.tif          – mosaicked, clipped 2021 RGB raster (INT1U, LZW)
##   data-large/ces/2024_rgb.tif          – mosaicked, clipped 2024 RGB raster (INT1U, LZW)
##
## Lesson code normalises pixel values: ces2021 / 255  (same as ces1961 / 255)
##
## After running this script you can safely delete:
##   data-large/ces/swissimage-dop10_2021_*.tif
##   data-large/ces/swissimage-dop10_2024_*.tif
##   data-large/SWISSTLM3D_2025.gpkg  (forest polys are already in data/ces.gpkg)

library(terra)
library(sf)

# ── 1. Build Forest/Non-forest polygon layers for 1999 and 2021 ────────────────
study_area <- read_sf("data/ces.gpkg", "Ces")

for (year in c(1999, 2021)) {
  forest <- read_sf("data/ces.gpkg", paste0("Wald_", year))

  non_forest_geom <- st_difference(st_geometry(study_area), st_union(st_geometry(forest)))

  layer <- rbind(
    st_sf(
      jahr  = year,
      area  = as.numeric(st_area(forest)),
      class = "Forest",
      geom  = st_geometry(forest)
    ),
    st_sf(
      jahr  = year,
      area  = as.numeric(st_area(non_forest_geom)),
      class = "Non-forest",
      geom  = non_forest_geom
    )
  )

  layer_name <- paste0("ces_polygons_", year)
  st_write(layer, "data/ces_polygons.gpkg", layer = layer_name,
           delete_layer = TRUE, quiet = TRUE)
  cat("Added layer:", layer_name,
      "| Forest:", round(layer$area[1] / 1e4), "ha",
      "| Non-forest:", round(layer$area[2] / 1e4), "ha\n")
}

# ── 2. Mosaic and clip RGB tiles for a given year ──────────────────────────────
mosaic_year <- function(year, study_area) {
  tiles <- list.files("data-large/ces",
                      pattern = paste0("swissimage-dop10_", year, ".*\\.tif$"),
                      full.names = TRUE)

  cat("\nFound", length(tiles), "tiles for", year, "— mosaicking...\n")

  r <- do.call(mosaic, lapply(tiles, rast))
  r <- crop(r, vect(study_area))
  r <- mask(r, vect(study_area))
  names(r) <- c("red", "green", "blue")

  out_path <- paste0("data-large/ces/", year, "_rgb.tif")
  writeRaster(r, out_path, overwrite = TRUE,
              datatype = "INT1U",
              gdal     = c("COMPRESS=DEFLATE", "PREDICTOR=2", "ZLEVEL=9"))

  size_mb <- round(file.size(out_path) / 1e6, 1)
  cat("Saved:", out_path, "\n")
  cat("  Resolution:", paste(res(r), collapse = " x "), "m |",
      "Size:", size_mb, "MB\n")
}

mosaic_year(2021, study_area)
mosaic_year(2024, study_area)

# ── 3. Compress historical grayscale TIFs ─────────────────────────────────────
cat("\nCompressing historical grayscale TIFs...\n")

for (yr in c(1961, 1971, 1977, 1983, 1989, 1995)) {
  f    <- paste0("data-large/ces/", yr, ".tif")
  ftmp <- paste0("data-large/ces/", yr, "_tmp.tif")
  before <- round(file.size(f) / 1e6, 1)
  writeRaster(rast(f), ftmp, datatype = "INT1U",
              gdal = c("COMPRESS=DEFLATE", "PREDICTOR=2", "ZLEVEL=9"))
  file.rename(ftmp, f)
  after <- round(file.size(f) / 1e6, 1)
  cat(" ", yr, ":", before, "MB →", after, "MB\n")
}

cat("\nDone. You can now delete:\n")
cat("  data-large/ces/swissimage-dop10_2021_*.tif\n")
cat("  data-large/ces/swissimage-dop10_2024_*.tif\n")
cat("  data-large/SWISSTLM3D_2025.gpkg\n")
