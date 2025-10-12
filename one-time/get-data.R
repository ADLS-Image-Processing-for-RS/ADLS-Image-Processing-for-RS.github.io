

data(Produc, package = "plm")

readr::write_csv(Produc, "data/Produc.csv")




f <- system.file("ex/lux.shp", package="terra")
v <- vect(f)
r <- rast(system.file("ex/elev.tif", package="terra"))
zones <- rasterize(v, r, "NAME_2")
