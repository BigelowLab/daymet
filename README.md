# daymet

Provides simplified access to OPeNDAP [daymet](https://daymet.ornl.gov/) data 
served by ORNL thredds server.

## Requirement

+ [R v3+](https://www.r-project.org/)

+ [ncdf4](https://CRAN.R-project.org/package=ncdf4)

+ [sp](https://CRAN.R-project.org/package=sp)

+ [raster](https://CRAN.R-project.org/package=raster)

## Installation

Using [devtools](https://CRAN.R-project.org/package=devtools)

```
devtools::install_github("BigelowLab/daymet")
```

## Accessing grids

First, instantiate a DaymetGridRefClass object with a uri. This process can take a bit of time
and requires some patience as two large matrices of cell locations are automatically
downloaded.

A uri can be constructed for a given year and parameter.

```
library(daymet)

(uri <- daymet_grid_uri(year = 2018, param = "tmin"))
# [1] "https://thredds.daac.ornl.gov/thredds/dodsC/ornldaac/1328/2018/daymet_v3_tmin_2018_na.nc4"

(X <- DaymetGrid(uri))
# please be patient as cell locations are downloaded
# Reference Class: "DaymetGridRefClass" 
# opened: https://thredds.daac.ornl.gov/thredds/dodsC/ornldaac/1328/2018/daymet_v3_tmin_2018_na.nc4 
```

Now get a layers for a specified bounding box.  Note that bounding box is required and defaults
to the boundary shown in the [help pages](https://daymet.ornl.gov/web_services.html). This is daily
data; we get two layers, one each for Jan 5 and Jan 6 of 2018.

```
bb <- c(-85.37, -81.29, 33.57, 36.61)
R <- X$get_raster(bb = bb, layers = c(5,6))
# class       : RasterStack 
# dimensions  : 390, 417, 162630, 2  (nrow, ncol, ncell, nlayers)
# resolution  : 1000, 1000  (x, y)
# extent      : 1249250, 1666250, -835500, -445500  (xmin, xmax, ymin, ymax)
# coord. ref. : +proj=lcc +lon_0=-100 +lat_0=42.5 +lat_1=25 +lat_2=60 +x_0=0 +y_0=0 +datum=WGS84 +units=m  +no_defs +ellps=WGS84 +towgs84=0,0,0 
# names       : layer.5, layer.6 
# min values  :   -22.0,   -22.5 
# max values  :    -7.0,    -6.5 

X$close()
```

Show the result on a map using leaflet. The blue polygon is the requested bounding
box, but, because of the Lambert projection, some additional data is retrieved 
in order to cover the entire request area.

```
library(leaflet)

leaflet() %>%
    addTiles() %>%
    addRasterImage(R[['layer.5']], project = TRUE, opacity = 0.6) %>%
    addPolygons(lng = bb[c(1,2,2,1,1)], lat = bb[c(3,3,4,4,3)], fill = FALSE)
```

![grid](https://github.com/BigelowLab/daymet/blob/master/inst/smokies.png)

## Accessing station data

[Station data](https://daac.ornl.gov/DAYMET/guides/Daymet_V3_Stn_Level_CrossVal.html) 
are stored by year and variable (tmin, tmax, prcp). The number of stations may vary by year. 
We provide facilities for searching for stations nearest to a user specified location, and 
for retrieving data for a specified station.

```
library(daymet)
library(leaflet)
library(magrittr)
uri <- daymet_station_uri(year = 2018, param = 'tmin')
X <- DaymetStations(uri)

lon = -70.180833
lat = 43.799444
x <- X$closest_stations(lon, lat)

# this is a little slow for first time use
# but subsequent calls for the same object instance are fast.
(station_name <- X$station_name(x$index))
 [1] "GRAY"                  "LONG IS"               "PORTLAND INTL JETPORT" "DURHAM"               
 [5] "WINDHAM 2NW"           "POLAND"                "BATH"                  "WISCASSET AP"         
 [9] "HOLLIS"                "TURNER"   

leaflet() %>%
    addTiles() %>%
    addMarkers(lng = x$lon, lat = x$lat,   
                label = station_name,
                labelOptions = labelOptions(noHide = T)) %>%
    addCircleMarkers(lng = lon, lat = lat, color = 'black',
                radius = 20,
                label = 'location',
                labelOptions = labelOptions(noHide = T))
```

![grid](https://github.com/BigelowLab/daymet/blob/master/inst/stations.png)


Extracting data for a station is pretty easy by station_name, station_id or index 
into the dataset.

```
library(tidyverse)

GrayMe <- X$station_data(name = "GRAY") %>%
    gather(type, tmin, -date)

X$close()

ggplot(data = GrayMe, aes(x=date, y=tmin, colour=type)) +
    geom_line() + 
    labs(y = "tmin (C)", title = "Gray, Maine: 2018 Minimum Daily Temperature")

```

![grid](https://github.com/BigelowLab/daymet/blob/master/inst/gray_me.png)
