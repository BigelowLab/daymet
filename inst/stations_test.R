setwd("/mnt/ecocast/corecode/R/daymet")
devtools::document() ; devtools::install()

library(ncdf4)
uri = "https://thredds.daac.ornl.gov/thredds/dodsC/ornldaac/1391/daymet_v3_stnsxval_tmin_2018.nc4"
#      https://thredds.daac.ornl.gov/thredds/dodsC/ornldaac/1391/daymet_v3_stnsxva_tmin_2018.nc4
X <- nc_open(uri)

if (exists("X") && X$is_open()) X$close()
X <- daymet::DaymetStations()
.self <- X
#x <- X$stnx()
lon = -70.180833
lat = 43.799444
x <- X$closest_stations(lon, lat)

library(leaflet)
library(magrittr)
leaflet() %>%
    addTiles() %>%
    addMarkers(lng = x$lon, lat = x$lat) %>%
    addCircleMarkers(lng = lon, lat = lat)


GrayMe <- X$station_data(name = "GRAY")



# File https://thredds.daac.ornl.gov/thredds/dodsC/ornldaac/1391/daymet_v3_stnsxval_tmin_2018.nc4 (NC_FORMAT_CLASSIC):
#
#      10 variables (excluding dimension variables):
#         char station_id[maxStrlen64,stns]
#             long_name: station id
#             cf_role: timeseries_id
#             _ChunkSizes: 1
#              _ChunkSizes: 255
#         char station_name[maxStrlen64,stns]
#             long_name: station name
#             standard_name: platform_name
#             _ChunkSizes: 1
#              _ChunkSizes: 255
#         double stnx[stns]
#             units: m
#             long_name: station projected x coordinate
#             _ChunkSizes: 512
#         double stny[stns]
#             units: m
#             long_name: station projected y coordinate
#             _ChunkSizes: 512
#         double stnz[stns]
#             long_name: station elevation
#             units: m
#             standard_name: altitude
#             positive: up
#             axis: Z
#             _ChunkSizes: 512
#         float time_bnds[nv,time]
#             _ChunkSizes: 365
#              _ChunkSizes: 2
#         double stn_lon[stns]
#             long_name: longitude coordinate
#             standard_name: longitude
#             units: degrees_east
#             _ChunkSizes: 512
#         double stn_lat[stns]
#             long_name: latitude coordinate
#             standard_name: latitude
#             units: degrees_north
#             _ChunkSizes: 512
#         double obs[time,stns]
#             units: degrees C
#             _FillValue: -9999
#             coordinates: stn_lat stn_lon stnz
#             long_name: observed temperature
#             _ChunkSizes: 1
#              _ChunkSizes: 365
#         double pred[time,stns]
#             units: degrees C
#             _FillValue: -9999
#             coordinates: stn_lat stn_lon stnz
#             long_name: predicted temperature
#             _ChunkSizes: 1
#              _ChunkSizes: 365
#
#      4 dimensions:
#         stns  Size:8648   *** is unlimited ***
#             long_name: station index
#             _ChunkSizes: 1024
#         maxStrlen64  Size:64
#         nv  Size:2
#         time  Size:365
#             long_name: time
#             calendar: standard
#             units: days since 1980-01-01 00:00:00 UTC
#             standard_name: time
#             _ChunkSizes: 365
#
#     9 global attributes:
#         _NCProperties: version=1|netcdflibversion=4.6.1|hdf5libversion=1.10.2
#         featureType: timeSeries
#         source: Daymet Software Version 3.0
#         Version_software: Daymet Software Version 3.0
#         citation: Please see http://daymet.ornl.gov/ for current Daymet data citation information
#         Version_data: Daymet Data Version 3.3
#         DODS.strlen: 255
#         DODS.dimName: descriptor_length
#         DODS_EXTRA.Unlimited_Dimension: stns
