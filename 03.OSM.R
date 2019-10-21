# open street maps data 

#load packages
library(tidyverse)
library(osmdata)
library(sf)
library(ggmap)

head(available_features())

head(available_tags("amenity"))

q <- getbb("Penticton")%>%
  opq()%>%
  add_osm_feature("amenity", "cinema")

str(q) 

cinema <- osmdata_sf(q)
cinema

plot(cinema)

#our background map
mad_map <- get_map(getbb("Penticton"),maptype = "toner-background")

#final map
ggmap(mad_map)+
  geom_sf(data=cinema$osm_polygons,
          inherit.aes =FALSE,
          colour="#238443",
          fill="#004529",
          alpha=.5,
          size=4,
          shape=21)+
  labs(x="",y="")



mapview::mapView(cinema$osm_polygons)



ggplot(cinema$osm_polygons)+
  geom_sf(colour="#08519c",
          fill="#08306b",
          alpha=.5,
          size=1,
          shape=21)+
  coord_sf(datum=NA)+
  theme_void()


# example of downloading data 
#bounding box for the Iberian Peninsula
m <- matrix(c(-10,5,30,46),ncol=2,byrow=TRUE)
row.names(m) <- c("x","y")
names(m) <- c("min","max")

#building the query
q <- m %>% 
  opq (timeout=25*100) %>%
  add_osm_feature("name","Mercadona")%>%
  add_osm_feature("shop","supermarket")

#query
mercadona <- osmdata_sf(q)

#final map
p <- ggplot(mercadona$osm_points)+
  geom_sf(colour="#08519c",
          fill="#08306b",
          alpha=.5,
          size=1,
          shape=21)+
  coord_sf(datum=NA)+
  theme_void()

mapview::mapView(mercadona$osm_points)


# Routing -----------------------------------------------------------------

install.packages("stplanr")
library(stplanr)
#> [1] "Data saved at: /tmp/RtmpppF3E2/Accidents0514.csv"
#> [2] "Data saved at: /tmp/RtmpppF3E2/Casualties0514.csv"
#> [3] "Data saved at: /tmp/RtmpppF3E2/Vehicles0514.csv"  

dl_stats19() 


