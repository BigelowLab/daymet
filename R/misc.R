#' Retrieve a coordinate reference string by name
#'
#' @export
#' @param name character - either 'longlat', or 'daymet' or 'native' The latter
#'   is the same as 'lcc'.
#' @return coordinate reference string in proj4 style
get_crs <- function(name = c("longlat", "lcc", "native")[1]){

    switch(tolower(name[1]),
           "longlat" = "+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0",
           paste("+proj=lcc +lon_0=-100 +lat_0=42.5 +lat_1=25 +lat_2=60",
                  "+x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs +ellps=WGS84",
                  "+towgs84=0,0,0"))
}

#' Retrieve the resolution
#'
#' @export
#' @return a two element [x,y] numeric
get_res <- function(){
  c(1000,1000)
}


#' Guess the parameter from the uri for gridded data
#'
#' @export
#' @param uri character the uri to the resource
#' @return character best guess of the parameter short hand
param_from_uri_grid <- function(uri = c("daymet_v3_tmin_2018_na.nc4")){
    sapply(strsplit(basename(uri), "_", fixed = TRUE), '[[', 3)
}


#' Guess the parameter from the uri for station data
#'
#' @export
#' @param uri character the uri to the resource
#' @return character best guess of the parameter short hand
param_from_uri_station <- function(uri = c("daymet_v3_stnsxval_prcp_1980.nc4")){
    sapply(strsplit(basename(uri), "_", fixed = TRUE), '[[', 4)
}




#' Build a daymet uri for gridded data
#'
#' @export
#' @param year 4 digit year (just one please)
#' @param mosaic character mosaic set (na, pr or hi)
#' @param param character the parameter name
#' @param interval character daily, monthly or annual
#' @param baseuri character, the base uri
#' @return charcater uri
daymet_grid_uri <- function(year = 2018,
                            mosaic = 'na',
                            param = 'tmin',
                            interval = 'daily',
                            baseuri = "https://thredds.daac.ornl.gov/thredds/dodsC/ornldaac"){

    # day    1328/2018/daymet_v3_tmin_2018_na.nc4
    # monavg 1345/daymet_v3_tmin_monavg_2017_na.nc4
    # momttl 1345/daymet_v3_prcp_monttl_1980_na.nc4
    # annttl 1343/daymet_v3_tmin_annavg_1980_na.nc4
    # annttl 1343/daymet_v3_prcp_annttl_1980_na.nc4

    port <- c(
        'daily'   = 1328,
        'monthly' = 1345,
        'annual'  = 1343 )
    mon <- c(
        prcp = "monttl",
        tmax = "monavg",
        tmin = "monavg",
        vp   = "monavg" )
    ann <- c(
        prcp = 'annttl',
        tmax = "annavg",
        tmin = "annavg",
        vp   = "annavg" )
    year <- sprintf("%0.4i", as.numeric(year[1]))
    bname <- switch(interval[1],
                    'daily'   = sprintf("daymet_v3_%s_%s_%s.nc4",
                                        param[1], year, mosaic[1]),
                    'monthly' = sprintf("daymet_v3_%s_%s_%s_%s.nc4",
                                        param[1], mon[param[1]], year, mosaic[1]),
                    'annual'  = sprintf("daymet_v3_%s_%s_%s_%s.nc4",
                                        param[1], ann[param[1]], year, mosaic[1])
    )
    switch(interval[1],
           'daily'   = file.path(baseuri, port[interval[1]], year, bname),
           file.path(baseuri, port[interval[1]], bname)
    )
}


#' Build a daymet uri for station data
#'
#' @export
#' @param year 4 digit year (just one please)
#' @param param character the parameter name
#' @param baseuri character, the base uri
#' @return charcater uri
daymet_station_uri <- function(year = 2018,
                            param = 'tmin',
                            baseuri = "https://thredds.daac.ornl.gov/thredds/dodsC/ornldaac/1391"){

    # daymet_v3_stnsxval_tmin_2018.nc4
    bname <- sprintf("daymet_v3_stnsxval_%s_%0.4i.nc4", param[1], as.numeric(year[1]))
    file.path(baseuri,  bname)
}



#' Transform a set of coordinates
#'
#' @export
#' @param x numeric locations such as decimal degrees longitude.  If y is not provided then
#'   x must be a two column matrix providing [x,y].
#' @param y numeric locations such as decimal degrees latitude
#' @param from_proj projection of the input coordinates
#' @param to_proj projection of the output coordinates
#' @return 2 column matrix of lcc [x,y]
points_transform <- function(x, y = NULL,
                      from_proj = get_crs("longlat"),
                      to_proj = get_crs("daymet")){

    if (!is.null(y)){
        if (!(length(x) == length(y)))
            stop("x and y must be same length")
    } else if (inherits(x, c('matrix', "numeric"))){
            y <- x[,2]
            x <- x[,1]
    } else {
        stop("x and y must be provided")
    }

    # possibly not correct but preserves my sanity
    from_names <- c("lon", "lat")
    to_names  <- c("x", "y")

    ll <- cbind(x, y)
    colnames(ll) <- from_names
    ix <- apply(ll, 1, function(x) any(is.na(x)) )
    input <- as.data.frame(ll[!ix,, drop = FALSE])
    sp::coordinates(input) <- from_names
    sp::proj4string(input) <- from_proj
    output <- as.matrix(sp::coordinates(sp::spTransform(input, to_proj)))
    ll[!ix, ] <- output
    colnames(ll) <- to_names
    ll
}
