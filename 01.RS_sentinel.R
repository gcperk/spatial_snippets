
install.packages(c("tidyverse","raster","RStoolbox","mapview","mapedit","rasterVis","purrr","geosphere","RColorBrewer"))
library(tidyverse)
library(raster)
library(RStoolbox)
library(mapview)
library(mapedit)
library(rasterVis)
library(purrr)
library(geosphere)
library(RColorBrewer)
```

## 1. Import a Sentinel-2 Satellite Image 

```{r import stack}
# Get data
unzip("../data/20191106_Day_2_PM_Raster/raster_sentinel_imagery.zip", exdir = "Exercise3_data")
# Make a list of the "TIF" files in a directory of interest
bands <- list.files(path = "Exercise3_data",                     
                    pattern = ".tiff$",
                    full.names = T)

# Print number of files in the directory
print(paste("We have", length(bands), "bands to import, they are:"))

# Import the list of "TIF" files as a multiband raster, termed a "stack"
img <- stack(bands)

# Print raster stack
print(img)
# Plot 

plot(img)  
```

## 2. Pre-processing

#### Bands Names

```{r use normal names}
print(names(img))
band_order <- c("B01","B02","B03","B04","B05","B06","B07","B08","B09","B10","B11","B12","B8A") 
band_names <- c("coastal","blue","green","red","re1","re2","re3","nir","vapor","cirrus","swir1","swir2","vre") 
names(img) <- band_names
names(img)
```

#### Plot

```{r plot}
# raster::plot
plotRGB(x = img,
        r = "red", 
        g = "green", 
        b = "blue",
        maxpixels = 1e+06, 
        stretch = "lin")
# mapview::viewRGB
viewRGB(x = img,
        r = "swir1",
        g = "nir",
        b = "red",
        maxpixels = 1e+06)
# RStoolbox::ggRGB
ggRGB(img = img, 
      r = "swir1", 
      g = "nir", 
      b = "red", 
      maxpixels = 1e+06, 
      stretch = "lin") 
```

## 3. Spectral indices

#### Calculat NDVI 

```{r}
## Calculate NDVI
normalized_difference <- function(img, b1, b2){
  out <- (img[[b1]]-img[[b2]])/(img[[b1]]+img[[b2]])
  return(out)}
ndvi <- normalized_difference(img, "nir", "red")
plot(ndvi)

# Use RStoolbox
ndvi <- spectralIndices(img, red = "red", nir = "nir", indices = "NDVI")
ndvi
ggR(ndvi)
```

```{r}
display.brewer.all()
display.brewer.pal(n = 10, name = "RdYlGn")
mypal <- brewer.pal(n = 10, name = "RdYlGn")
plot(ndvi, col = mypal)
```

```{r}
veg <- reclassify(ndvi, cbind(-Inf, 0.4, NA))
plot(veg, col = brewer.pal(4, "Greens"))
```

```{r}
plotRGB(img, r="nir", g="red", b="green", axes=TRUE, stretch="lin", main="Landsat False Color Composite with NDVI Overlay",)
plot(veg, col = brewer.pal(10, "Greens"), add=TRUE, legend=FALSE)
```

## 4. Classification 

Run a classifier

```{r}
# Assign 0 / No Data to -9999
ndvi_na <- ndvi
ndvi_na[ndvi_na == 0] <- -9999
# Convert raster to numeric
nr <- getValues(ndvi_na)
# Set random number generator seed
set.seed(23)
# Run cluster analysis for 10 groups
kmncluster <- kmeans(x = na.omit(nr), centers = 20)
# Insert cluster values into the raster structure
knr <- setValues(ndvi_na, kmncluster$cluster)
# Plot
mapview(knr)
```

## 5. Zonal Analysis 

```{r}
# Get mean band values of each zone
zonal_means <- zonal(x = img, 
                     z = knr, 
                     fun = mean, 
                     na.rm = T)
# Plot the zonal means
zonal_means %>% 
  as.tibble() %>% 
  gather("band","mean", -zone) %>% 
  ggplot(aes(x = band, y = mean, group = zone)) + 
  geom_line(aes(color = as.factor(zone))) +
  geom_point(aes(fill = as.factor(zone)), shape = 21, size = 3) + 
  theme_bw() +
  labs(x = "Band Name", 
       y = "Mean Spectral Value", 
       fill = "Zone", 
       color = "Zone", 
       title = "Mean spectral values by kmeans zone")
```

# Extract water class as polygons

```{r}
# Make a copy of the classified raster 
temp <- knr
# Set classes that are not water to NA
temp[temp != 18 & temp != 2] <- NA
# Mask the classified raster
mr <- mask(knr, temp)
# Set classes that are not water to NA
mr[mr > 0] <- 1
# Plot
plot(mr)
# Convert water class to polygons
mypoly <- rasterToPolygons(x = mr, dissolve = T)
# Plot water polygons 
mapview(mypoly)
```
## 6. Plot NDVI Against Elevation

``` {r} 
library(sf)
line <- cbind(c(-122.67618, -122.81251), 
              c(53.88945, 53.88288)) %>%
  st_linestring() %>% 
  st_sfc(crs = 4326) %>% 
  st_sf()
ndvi_t <- projectRaster(ndvi, crs = crs(line))
ggR(ndvi_t) + 
  geom_sf(data = line, size = 2, color = "red")
transect  <-  raster::extract(ndvi_t, line, along = T, cellnumbers=T)
transect_df = purrr::map_dfr(transect, as_data_frame, .id = "ID")
transect_coords = xyFromCell(ndvi_t, transect_df$cell)
pair_dist = geosphere::distGeo(transect_coords)[-nrow(transect_coords)]
transect_df$dist = c(0, cumsum(pair_dist))
ggplot(transect_df) +
  geom_line(aes(dist, NDVI))
````