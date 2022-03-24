# https://www.unidata.ucar.edu/software/tds/current/reference/NetcdfSubsetServiceReference.html

# https://thredds.daac.ornl.gov/thredds/ncss/grid/ornldaac/1328/2019/daymet_v3_dayl_2019_na.nc4/dataset.html

# https://thredds.daac.ornl.gov/thredds/ncss/ornldaac/1328/2019/daymet_v3_dayl_2019_na.nc4?var=dayl&north=48.15&west=-74&east=-59.75&south=41&disableProjSubset=on&horizStride=1&time_start=2019-01-01T12%3A00%3A00Z&time_end=2019-01-03T12%3A00%3A00Z&timeStride=1&accept=netcdf

# https://github.com/ornldaac/gridded_subset_example_script

# https://thredds.daac.ornl.gov/thredds/ncss/grid/ornldaac/1328/`[YEAR]/daymet_v3_[DAYMETVAR]_[YEAR]_[region].nc4


#' Retrieve the NCSS root url
#'
#' @export
#' @return character url to thredds subset service
ncss_root_url <- function(){
  'https://thredds.daac.ornl.gov/thredds/ncss/grid/ornldaac/1328'
}

#' Generate a NCSS url for the given year, variable and region
#'
#' @export
#' @param year character or numeric, 4 digit year to access
#' @param var character, the variable name
#' @param region character, the name of the region (default 'na')
#' @param version character, "v4"
#' @param root character, the root URL
#' @return the base url
ncss_base_url <- function(year = format(Sys.Date()-365, "%Y"),
                     var = "dayl",
                     region = "na",
                     version = daymet_version(),
                     root = ncss_root_url()){

    if (is.numeric(year)) year <- sprintf("%0.4i", year)
    file.path(root,
              year,
              sprintf("daymet_%s_%s_%s_%s.nc4", version, var, year, region))
}

#' Handle miscellaneous query elements
#'
#' @export
#' @param disableProjSubset character either on or off
#' @param horizStride numeric
#' @param timeStride numeric
#' @param accept charcater
ncss_query_misc <- function(disableProjSubset ="on",
                            horizStride = 1,
                            timeStride = 1,
                            accept = "netcdf"){

  list(disableProjSubset = disableProjSubset,
       horizStride = horizStride,
       timeStride = timeStride,
       accept = accept)
}

#' Generate a NCSS url with subset qualifiers
#'
#' @seealso \url{https://daymet.ornl.gov/web_services}
#'
#' @export
#' @param var character, the variable name
#' @param region character, the name of the region (default 'na')
#' @param dates Date 2 element Date vector with inclusive start/stop dates.
#'   These should fall within one calendar year.
#' @param bb a 4 element bounding box [west, east, south, north]
#' @param ... items for \code{\link{ncss_query_misc}}
#' @return charcater URL with query terms
ncss_url <- function(var = 'dayl',
                     region = 'na',
                     dates = as.Date(c("2019-01-01", "2019-01-31")),
                     bb = c(-157.0759, -6.1376, 6.0761, 83.0163),
                     ...){

  year <- unique(format(dates, "%Y"))
  if (length(year) > 1){
    stop("dates must fall within one calendar year")
  }
  base <- ncss_base_url(year = year, region = region[1], var = var[1])
  misc <- ncss_query_misc(...)
  query <- paste(c(
      sprintf("var=%s", var[1]),
      sprintf("north=%0.4f&west=%0.4f&east=%0.4f&south=%0.4f", bb[4], bb[1], bb[2], bb[3]),
      sprintf("disableProjSubset=%s&horizStride=%i", misc$disableProjSubset, misc$horizStride),
      sprintf("time_start=%sT12%%3A00%%3A00Z&time_end=%sT12%%3A00%%3A00Z", dates[1], dates[2]),
      sprintf("timeStride=%i&accept=%s", misc$timeStride, misc$accept)),
    collapse = "&")
  paste(base, query, sep = "?")
}

#' Extract the file basename out of a ncss_url
#'
#' @export
#' @param uri character, the uri to parse
#' @return character, the file basename
ncss_basename <- function(uri = ncss_base_url()){
  strsplit(basename(uri), "?", fixed = TRUE)[[1]][1]
}


#' Download a NCSS resource as NetCDF
#'
#' @export
#' @param uri character, the URL of the resource
#' @param dest character, file and path of the destination file
#' @param quiet logical see \code{\link[utils]{download.file}}
#' @return named logical where TRUE is success
ncss_download <- function(uri = ncss_url(),
                          dest = file.path(".", ncss_basename(uri)),
                          quiet = TRUE){

  path <- dirname(dest)
  if (!dir.exists(path)) ok <- dir.create(path, recursive = TRUE)

  #ok <- system2("wget", args = c(uri, sprintf("--output-document=%s", dest))) == 0
  #ok <- system(sprintf("wget -O %s '%s'", dest, uri))
  ok <- download.file(uri, dest, quiet = quiet) <= 0

  if (ok) {
    ok <- sapply(dest, file.exists)
  } else {
    ok <- FALSE
    names(ok) <- dest
  }
  ok
}


#' Load NCSS data as a raster brick
#'
#' @export
#' @param filename character, the path and name of the NCDF file to read
#' @param modify_spatial logical, if TRUE then update the projection and resolution
#' @return \{code{\link[raster]{brick}} object
ncss_read_brick <- function(filename, modify_spatial = TRUE){

  B <- suppressWarnings(raster::brick(filename))
  if (modify_spatial[1]){
    raster::crs(B) <- get_crs("lcc")
    raster::extent(B) <- as.vector(raster::extent(B)) * get_res()[c(1,1,2,2)]
  }
  B
}
