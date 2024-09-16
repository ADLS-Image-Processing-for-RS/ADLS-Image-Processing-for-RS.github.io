
library(terra)
library(purrr)
library(forcats)
nrows <- c(10, 100, 1000)
res_df <- map_dfr(nrows, \(nrow){
  ncol <- nrow
  
  mat <- matrix(as.integer(runif(nrow*ncol, 0, 255)), ncol = ncol)
  
  
  datatypes <- c("INT1U", "INT2U", "INT2S", "INT4U", "INT4S", "FLT4S", "FLT8S", "INT8U", "INT8S")
  
  
  res <- map_dbl(datatypes, \(type){
    if(file.exists("test.tif")) file.remove("test.tif")
    rast(mat) |> 
      writeRaster("test.tif",datatype = type)
    si <- file.size("test.tif")
    file.remove("test.tif")
    si
  })
  
  tibble(datatypes, res)|>
    mutate(nrow = nrow, ncol = ncol)
  
})


res_df2 <- res_df |>
  mutate(
    datatypes = fct_reorder(datatypes, res)
  ) |>
  mutate(
    res_fac = res/min(res), .by = nrow
  )

res_df2 |>
  ggplot(aes( y = datatypes))+
  geom_errorbarh(xmin = 1, aes(xmax = res_fac), height = 0)+
  geom_point(aes(x = res_fac)) +
  facet_wrap(~nrow)
