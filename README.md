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
and requires some patience as two large matrices of cell lccations are automatically
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

[!grid](https://github.com/BigelowLab/daymet/blob/master/inst/smokies.png)

## Accessing station data

TODO
