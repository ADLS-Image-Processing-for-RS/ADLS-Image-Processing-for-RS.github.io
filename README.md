# RasterDataProcessing

# Topics

## Lesson 1

- The raster data model:
  - in R (terra) / in python (rioxarray)
  - in comparison to classic data-frame type data (long vs wide data, data cubes, dense vs. sparse)
  - singleband and multiband datasets
  - raster data types and their implications (float / int, pseudo-categorical)
  - raster NA values
- Raster file formats (geotif, COG, XYZ → binary vs. non-binary data)

## Lesson 2

- Raster operations
  - local, zonal, focal, global in theory
- each of the above in practice, starting with the easiest and using concrete examples  (in R and/or Python)
  - Global: mean canopy cover (?) for the image
  - Zonal: Mean Canopy cover for the burt area
  - local: NDVI > 1
  - focal: tbd
 
## Lesson 3

- Pixel based Supervised classification with categorical data
  - (e.g. Landuse Classification using Sentinel Data or historical map data)
- Pixel based unsupervised classification with categorical data
  - find some hand annotated maps similar to the flughafen data or other historical data such as [this one](https://www.usgs.gov/programs/national-geospatial-program/historical-topographic-maps-preserving-past) or [this](https://map.geo.admin.ch/#/map?lang=en&center=2660000,1190000&z=1&bgLayer=ch.swisstopo.pixelkarte-farbe&topic=ech&layers=ch.swisstopo.zeitreihen@year=1864;ch.bfs.gebaeude_wohnungs_register,f;ch.bav.haltestellen-oev,f;ch.swisstopo.swisstlm3d-wanderwege,f;ch.vbs.schiessanzeigen,f;ch.astra.wanderland-sperrungen_umleitungen,f)


## Lesson 4

- Feature engineering using focal methods
- DataChallenge: Forest detection in Ces
