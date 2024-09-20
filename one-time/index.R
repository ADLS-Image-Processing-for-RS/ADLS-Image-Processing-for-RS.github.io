

tif <- system.file("tif/L7_ETMs.tif", package = "stars")


library(terra)

l7 <- rast(tif)

plotRGB(l7[[c(4,2,1)]])

# Band 1 Blue (0.45 - 0.52 µm) 30 m
# Band 2 Green (0.52 - 0.60 µm) 30 m
# Band 3 Red (0.63 - 0.69 µm) 30 m
# Band 4 Near-Infrared (0.77 - 0.90 µm) 30 m
# Band 5 Short-wave Infrared (1.55 - 1.75 µm) 30 m
# Band 6 Thermal (10.40 - 12.50 µm) 60 m Low Gain / High Gain
# Band 7 Mid-Infrared (2.08 - 2.35 µm) 30 m
# Band 8 Panchromatic (PAN) (0.52 - 0.90 µm) 15 m
