#' An object that connects to opendap daymet grids using ncdf4
#'
#' @export
#' @field NC the ncdf4 class objects
#' @field bag a list (bag of goodies) useful for navigating the ncdf object, see \code{\link{daymet_bag}}
DaymetGridRefClass <- setRefClass("DaymetGridRefClass",
    fields = list(
        NC = 'ANY',
        bag = 'ANY'
    ),
    methods = list(
        initialize = function(path, ...){
             ok <- .self$open(path, ...)
             if (ok){
                 BAG = daymet_bag(.self$NC)
                 .self$field("bag", BAG)
             }
        },
        finalize = function(){
            ok <- .self$close()
        },
        show = function(){
            cat("Reference Class:", classLabel(class(.self)), "\n")
            if(.self$is_open()){
                cat("opened:", .self$NC$filename, "\n")
            } else {
                cat("resource is closed \n")
            }
        },
        open = function(path, ...){
            ok <- .self$is_open()
            if (ok == TRUE){
                cat("the connection is already open!\nPlease close before reopening\n")
                return(FALSE)
            }
            nc <- try(ncdf4::nc_open(path,...))
            if (inherits(nc, "try-error")){
                cat("unable to nc_open() the path:", path, "\n")
                .self$field("NC", NULL)
                return(FALSE)
            }

            .self$NC <- nc
            return(.self$is_open())
        },
        is_open = function(){
            !is.null(.self$NC) && inherits(.self$NC, "ncdf4")
        },
        close = function(){
             ok <- .self$is_open()
             if (ok) ncdf4::nc_close(.self$NC)
             .self$field("NC", NULL)
             .self$field("bag", NULL)
             return(TRUE)
         })
)

#' Retrieve one or more raster layers for the user specified boundaries and
#' layers.
#'
#' @name DaymetGridRefClass_get_raster
#' @param bb numeric, 4 element bounding box specified in degrees lon and lat in
#' [left, right, bottom, top] order where west and south are negative.
#' @param layers numeric one or more 1-based layer index.  If more than one then a
#' multi-layer raster is returned.  Note that contiguous layers (e.g. 7, 8, 9) are faster
#' to retrieve than non-contiguous layers (e.g. 3, 7, 9).  The units of the layer
#' vary with the data source: for dailies layer is day-of-year.  For monthlies
#' layer is month-of-year.
#' @param ... further arguments for \code{\link{daymet_index}}
#' @return a Raster* or NULL
NULL
DaymetGridRefClass$methods(
    get_raster = function(bb = c(-85.37, -81.29, 33.57, 36.61),
                          layers = 1, ...){
        daymet_raster(.self$NC,
                      bb = bb,
                      layers = layers,
                      bag = .self$bag, ...)
    })

#' Establish a DaymetGridRefClass object
#'
#' @export
#' @param uri the uri of the daymet grid resource
#' @return DaymetGridRefRefClass object
DaymetGrid <- function(uri = daymet_grid_uri()){
    DaymetGridRefClass$new(uri)
}


#' Construct a daymet ncdf object bag of goodies
#'
#' @export
#' @param x a ncdf4 object
#' @param verbose logical if TRUE then issue a polite message about the wait
#' @return bag a list (bag of goodies) useful for navigating the ncdf object.
#' It includes the following elements
#' \itemize{
#'     \item{param character, the parameter name}
#'     \item{crs character the CRS projection string}
#'     \item{res numeric the grid cell size in meters}
#'     \item{lon numeric matrix of cell locations in degrees longitude}
#'     \item{lat numeric matrix of cell locations in degrees latitude}
#'     \item{x the east-west cell locations (meters)}
#'     \item{y the north south cell locations (meters)}
#' }
daymet_bag <- function(x, verbose = TRUE){
    if (verbose) message("please be patient as cell locations are downloaded")
    list(
        param = param_from_uri_grid(x$filename),
        crs = get_crs("daymet"),
        res = 1000,
        lon = t(ncdf4::ncvar_get(x, "lon")),
        lat = t(ncdf4::ncvar_get(x, "lat")),
        x  = as.vector(x$dim$x$vals),
        y  = as.vector(x$dim$y$vals))
}




#' Retrieve one or more raster layers of daymet data
#'
#' @export
#' @param x a ncdf4 object
#' @param param character, name of the variable
#' @param nav list of navigation items, see \code{\link{daymet_nav}}
#' @return RasterLayer or RasterStack
fetch_daymet_raster <- function(x, param, nav){
    v <- ncdf4::ncvar_get(x, param, start = nav$start, count = nav$count)
    if (inherits(v, "matrix")){
        r <- raster::raster(t(v), template = nav$template)
    } else {
        nlyr <- dim(v)[3]
        r <- raster::stack(
            lapply(seq_len(nlyr),
                function(lyr) {
                    raster::raster(t(v[,,lyr]), template = nav$template)
                }))
        names(r) <- paste("layer", seq(from = nav$start[3], length = nav$count[3]) )
    }
    r
}


#' Retrieve one or more raster layers of daymet data
#'
#' @export
#' @param x a ncdf4 object
#' @param bb numeric, 4 element bounding box specified in degrees lon and lat in
#' [left, right, bottom, top] order where west and south are negative.
#' @param layers numeric one or more 1-based layer index.  If more than one then a
#' multi-layer raster is returned.  Note that contiguous layers (e.g. 7, 8, 9) are faster
#' to retrieve than non-contiguous layers (e.g. 3, 7, 9).  The units of the layers
#' vary with the data source: for dailies layer is day-of-year (1-365).  For monthlies
#' layer is month-of-year (1-12).
#' @param bag list produced by \code{daymet_bag()}
#' @param ... further arguments for \code{\link{daymet_index}}
#' @return a Raster* or NULL
daymet_raster <- function(x,
                          bb = c(-77, -51.5, 37.9, 56.7),
                          layers = 1,
                          bag = daymet_bag(x), ...){


    R <- NULL
    if (length(layers) == 1){
        nav <- daymet_nav(bb, layers, bag, ...)
        R <- fetch_daymet_raster(x, bag$param, nav)
    } else {
        d <- diff(layers) == 1
        if (all(d)){
            nav <- daymet_nav(bb, layers, bag, ...)
            R <- fetch_daymet_raster(x, bag$param, nav)
        } else{
            SS <- lapply(layers,
                         function(i){
                             nav <- daymet_nav(bb, i, bag, ...)
                             fetch_daymet_raster(x, bag$param, nav)
                         })
            R <- raster::stack(SS)
        }
    }
    R
}

#' Compute indices into daymet arrays from lon/lat or from the native
#' daymet Lambert conformal conic coordinates
#'
#' @export
#' @param lon vector of longitudes
#' @param lat vector of latitudes
#' @param bag a list containing look up values of daymet array lons and lats
#' @param crs character indicating what proj the inputs belong to "longlat" or "daymet"
#' @param bbox logical if TRUE assume we are trying to find the enclosing bbox, which
#'   trims the result to the maximum range in x and.
#' @return a two column vector of closest indices in [x,y] order
daymet_index <- function(lon, lat, bag, crs = c("longlat", "daymet", "native")[1],
                         bbox = FALSE){

    stopifnot(length(lon) == length(lat))

    if (tolower(crs[1]) == 'longlat'){

        #find the index of one location
        index_one <- function(lon, lat, lons, lats){
            d = sqrt((lats - lat)^2 + (lons - lon)^2)
            which.min(d)
        }
        # iterate through the provided points
        ix <- sapply(seq_along(lon),
                     function(i) {
                         ix <- index_one(lon[i], lat[i], bag$lon, bag$lat)
                     } )
        xy <- arrayInd(ix, dim(bag$lon), useNames = TRUE)[,c(2,1)]
    } else{
        ix <- sapply(lon, function(x) which.min(abs(bag$x - x)))
        iy <- sapply(lat, function(y) which.min(abs(bag$y - y)))
        xy <- cbind(ix, iy)
    }
    if (bbox){
        #we should be in indices, so just find the range of each
        xy <- apply(xy, 2, range)
    }

    colnames(xy) <- c("col", "row")
    return(xy)
}

#' Prepare a navigation list for subsetting daymet arrays
#'
#' @export
#' @param bb a 4-element bounding box in [left, right, bottom, top] order
#' @param layer sequences of one or more contiguous layer numbers (in range of 1-365 or 1-12)
#' @param bag a list containing the lons, lats, crs and resolution of native daymet data
#' @param ... further arguments for \code{\link{daymet_index}}
#' @return a list with
#'  \itemize{
#'     \item{start a 3 element vector of starts for x, y and t}
#'     \item{count a 3 element vector of run lengths for x, y and t}
#'     \item{template an empty Raster layer object}
#' }
daymet_nav <- function(bb, layer = 1, bag, ...){

    # get the indices for every corner of the bounding box
    xy <- daymet_index(bb[c(1,2,2,1)], bb[c(3,3,4,4)], bag = bag, bbox = TRUE,...)

    # select the bounding box of those
    #xy <- cbind(range(xy[,1]), range(xy[,2]))

    # compute the lengths
    count <- abs(apply(xy, 2, diff)) + 1

    half <- bag$res/2

    list(start = c(min(xy[,1]), min(xy[,2]), min(layer)),
         count = c(count, length(layer)),
         template = raster::raster(ncols = count[1],
                                   nrows = count[2],
                                   #resolution = bag$res,
                                   xmn = bag$x[ min(xy[,1]) ] - half,
                                   xmx = bag$x[ max(xy[,1]) ] + half,
                                   ymn = bag$y[ max(xy[,2]) ] - half, # swapped
                                   ymx = bag$y[ min(xy[,2]) ] + half, # swapped
                                   crs = bag$crs)
    )
}
