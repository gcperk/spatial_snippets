#remotes::install_github("ropensci/tidyhydat")


library(tidyhydat)
library(dplyr)

#download_hydat()  # download the hydat dataset 
hy_dir() # where is the hydat data downloaded. 


# get all of BV 
BC_stns <- hy_stations() %>%
  filter(HYD_STATUS == "ACTIVE") %>%
  filter(PROV_TERR_STATE_LOC == "BC") %>%
  pull_station_number()

BC_stns

hy_daily_flows(station_number = BC_stns)

# get single station: flow data 

hdata <- hy_daily_flows(station_number = "08NM050")
#hdata1 <- hy_daily_flows(station_number = "08NM084")
#"08NM050" - pentictan
# "08NM084" SKAHA LAKE - doesn't record flow

unique(hdata$Parameter) # Flow

# Values 
hist(hdata$Value)

unique(hdata$Symbol)

data.type <- hdata %>%
  group_by(Symbol) %>%
  summarise(count = n())

# Real time data: 
# note this is unvetted data sources:

library(mapview)

library(ggplot2)
library(bcmaps)
library(sf)


#realtime_stations("08NM084")
bcrt <- realtime_stations(prov_terr_state_loc = "BC") 



bcrt_sf <- st_as_sf(bcrt, coords = c("LATITUDE", "LONGITUDE")) %>%
  left_join(st_coordinates)

bc <- bc_bound() %>%
  st_simplify(., TRUE, 10) %>%
  st_transform(4326)


# create a leaflet map 

library(leaflet)
library(envreportutils)

watermap <- leaflet(width = "900px", height = "600px", 
                    options = leafletOptions(minZoom = 5)) %>%  # generate leaflet map
  addProviderTiles(providers$Stamen.Terrain, group = "Terrain") %>%
  add_bc_home_button() %>%
  set_bc_view()




watermap  %>% 
  addPolygons(data = bc, 
              stroke = T, weight = 1, color = "black", # Add border to polygons
              fillOpacity = 0.5) %>%
  addMarkers(bcrt, ~LATITUDE, ~LONGITUDE)

# Create a palette that maps factor levels to colors
pal <- colorFactor(c("navy", "red"), domain = c("ship", "pirate"))

leaflet(df) %>% addTiles() %>%
  addCircleMarkers(
    radius = ~ifelse(type == "ship", 6, 10),
    color = ~pal(type),
    stroke = FALSE, fillOpacity = 0.5
  )


  
# Notes

# water level and stream flow 
#E - Estimated : indicates that there was no measured data available for the day or missing period, and the water level or streamflow value was estimated by an indirect method such as interpolation, extrapolation, comparison with other streams or by correlation with meteorological data.
#A - Partial Day : The symbol A indicates that the daily mean value of water level or streamflow was estimated despite gaps of more than 120 minutes in the data string or missing data not significant enough to warrant the use of the E symbol.
#B - Ice conditions : The symbol B indicates that the streamflow value was estimated with consideration for the presence of ice in the stream. Ice conditions alter the open water relationship between water levels and streamflow.
#D - Dry: The symbol D indicates that the stream or lake is "dry" or that there is no water at the gauge. This symbol is used for water level data only.
#R - Revised : The symbol R indicates that a revision, correction or addition has been made to the historical discharge database after January 1, 1989.

# REFERENCES: 

#https://cran.r-project.org/web/packages/tidyhydat/vignettes/tidyhydat_an_introduction.html

# Search the station numbers 
#https://wateroffice.ec.gc.ca/google_map/google_map_e.html?map_type=real_time&search_type=province&province=BC
#https://www.canada.ca/en/environment-climate-change/services/meteorological-service-standards/publications/hydrometric-data-information/chapter-1.html
#https://wateroffice.ec.gc.ca/contactus/faq_e.html#targetText=The%20symbol%20A%20indicates%20that,use%20of%20the%20E%20symbol.&targetText=This%20symbol%20is%20used%20for%20water%20level%20data%20only.

#North American Water Data:
#https://watermonitor.gov/naww/index.php
#https://water.weather.gov/ahps2/hydrograph.php?wfo=sew&gage=nksw1

