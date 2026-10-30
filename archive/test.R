path <- "data-large/S2B_MSIL2A_20240915T102559_N0511_R108_T32TMS_20240915T131207.SAFE/GRANULE/L2A_T32TMS_A039316_20240915T102803/IMG_DATA/R10m/"

mybands <- list.files(path, pattern = "B\\d{2}", full.names = TRUE)

s2 <- rast(mybands)

hist(s2)

s2 <- (s2 - 1000) / 10000

hist(s2)
