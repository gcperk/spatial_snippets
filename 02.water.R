remotes::install_github("ropensci/tidyhydat")

library("tidyhat")

library(tidyhydat)
library(dplyr)

download_hydat()
hy_daily_flows(station_number = "08LA001")


