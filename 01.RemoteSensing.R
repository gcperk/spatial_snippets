
# Remote Sensed Data accquisition 

# Canadian Free Lidar Data
#https://canadiangis.com/free-canada-lidar-data.php


#Landsat 
install.packages("rLandsat")

# Install the latest dev version from GitHub:
install.packages("devtools")
devtools::install_github("socialcopsdev/rLandsat")

# Load the library
library(rLandsat)

# get all the product IDs for India, alternatively can define path and row
result = landsat_search(min_date = "2018-01-01", max_date = "2018-01-16", country = "India")

# inputting espa creds
espa_creds("yourusername", "yourpassword")

# getting available products
prods = espa_products(result$product_id)
prods = prods$master

# placing an espa order
result_order = espa_order(result$product_id, product = c("sr","sr_ndvi"),
                          projection = "lonlat",
                          order_note = "All India Jan 2018")
order_id = result_order$order_details$orderid

# getting order status
durl = espa_status(order_id = order_id, getSize = TRUE)
downurl = durl$order_details

# download; after the order is complete
landsat_download(download_url = downurl$product_dload_url, dest_file = getwd())



# Sentinel ----------------------------------------------------------------
unzip("../data/20191106_Day_2_PM_Raster/raster_sentinel_imagery.zip", exdir = "Exercise3_data")



# Lidar -------------------------------------------------------------------

#install.packages(c("rLiDAR)"))
library(lidR)
library(rlas)
#library(rLiDAR)

data.dir <- "C:/Temp/00.Ninox/Floodmapping/Data/Lidar"


files <- list.files(data.dir)

las <- lidR::readLAS(file.path(data.dir,"points.las" ))
#las <- lidR::readLAS(files[1])#, select = "xyz", filter = "keep_first")
las
las@data
las@header
las@bbox
las@proj4string
lascheck(las)
plot(las)
e <- extent(las@bbox)
e <- e + 1000 # add this as all y's are the same
xmin = e[1]
xmax = e[2]
ymin = e[3]
ymax = e[4]
f <- 2
r <- raster(e, ncol=(xmax-xmin)/f, nrow=(ymax - ymin)/f)
x <- rasterize(las@data[, 1:2], r, las@data[,3], fun=min)

writeRaster(x = x, filename = file.path(data.dir,"points.tif"))

x <- raster()

# convert to contours 

area(las)

library(raster)
library(sf)
library(ggplot2)
library(dplyr)

#con <- rasterToContour(x)
#con_sf <- st_as_sf(con)

unique(x$layer)

conp <- rasterToPolygons(x) # too slow 

conp_sf <- st_as_sf(conp)
plot(conp_sf)

conp_sf <- conp_sf %>%
  mutate(zclass = as.numeric(layer))


# convert raster to polygon. Note this also takes some time
library(stars)

x <- st_as_stars(x) %>% 
  st_as_sf() %>% # this is the raster to polygons part
  st_cast("MULTIPOLYGON") # cast the polygons to polylines


plot(x)




head(conp_sf)

ggplot() +
  geom_sf(data =con_sf)


ggplot() + 
  geom_line(con_sf)

# open street maps
https://dominicroye.github.io/en/2018/accessing-openstreetmap-data-with-r/
