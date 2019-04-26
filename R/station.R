#' An object that connects to opendap daymet stations using ncdf4
#'
#' @export
#' @field NC the ncdf4 class objects
#' @field stns numeric, the number of stations represented
#' @field .station_id private, please use method station_id()
#' @field .station_name private, please use method station_name()
#' @field .stnz private, please use method stnz()
#' @field .stnx private, please use method stnx()
#' @field .stny private, please use method stny()
#' @field .stn_lon private, please use method stn_lon()
#' @field .stny_lat private, please use method stn_lat()
#' @field .dates private, please use method dates()
DaymetStationsRefClass <- setRefClass("DaymetStationsRefClass",
    fields = list(
        NC = 'ANY',
        stns = "numeric",
        .station_id = "ANY",
        .station_name = "ANY",
        .stnz = "ANY",
        .stnx = "ANY",
        .stny = "ANY",
        .stn_lon = "ANY",
        .stn_lat = "ANY",
        .dates = "ANY"
    ),
    methods = list(
        initialize = function(path, ...){
            ok <- .self$open(path, ...)
            if (ok){
                .self$field("stns", .self$NC$dim$stns$len)
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
            return(TRUE)
        })
)

#' Retrieve the station ids
#'
#' @name DaymetStationsRefClass_station_id
#' @param index numeric, the indices to return
#' @return character vector of station ids
DaymetStationsRefClass$methods(
    station_id = function(index = seq_len(.self$stns)){
        if (inherits(.self$.station_id, "uninitializedField")){
            .self$field(".station_id",
                        trimws(as.vector(ncdf4::ncvar_get(.self$NC, "station_id"))))
        }
        .self$.station_id[index]
    })

#' Retrieve the station names
#'
#' @name DaymetStationsRefClass_station_name
#' @param index numeric, the indices to return
#' @return character vector of station names
DaymetStationsRefClass$methods(
    station_name = function(index = seq_len(.self$stns)){
        if (inherits(.self$.station_name, "uninitializedField")){
            .self$field(".station_name",
                        trimws(as.vector(ncdf4::ncvar_get(.self$NC, "station_name"))))
        }
        .self$.station_name[index]
    })

#' Retrieve the station x locations
#'
#' @name DaymetStationsRefClass_stnx
#' @param index numeric, the indices to return
#' @return numeric vector of x locations
DaymetStationsRefClass$methods(
    stnx = function(index = seq_len(.self$stns)){
        if (inherits(.self$.stnx, "uninitializedField")){
            .self$field(".stnx",
                        as.vector(ncdf4::ncvar_get(.self$NC, "stnx")))
        }
        .self$.stnx[index]
    })


 #' Retrieve the station y locations
 #'
 #' @name DaymetStationsRefClass_stny
 #' @param index numeric, the indices to return
 #' @return numeric vector of y locations
 DaymetStationsRefClass$methods(
     stny = function(index = seq_len(.self$stns)){
         if (inherits(.self$.stny, "uninitializedField")){
             .self$field(".stny",
                         as.vector(ncdf4::ncvar_get(.self$NC, "stny")))
         }
         .self$.stny[index]
     })

#' Retrieve the station z elevations
#'
#' @name DaymetStationsRefClass_stnz
#' @param index numeric, the indices to return
#' @return numeric vector of z elevations
DaymetStationsRefClass$methods(
    stny = function(index = seq_len(.self$stns)){
        if (inherits(.self$.stnz, "uninitializedField")){
            .self$field(".stnz",
                        as.vector(ncdf4::ncvar_get(.self$NC, "stnz")))
        }
        .self$.stnz[index]
    })

#' Retrieve the station lon locations
#'
#' @name DaymetStationsRefClass_stn_lon
#' @param index numeric, the indices to return
#' @return numeric vector of lon locations
DaymetStationsRefClass$methods(
    stn_lon = function(index = seq_len(.self$stns)){
        if (inherits(.self$.stn_lon, "uninitializedField")){
            .self$field(".stn_lon",
                        as.vector(ncdf4::ncvar_get(.self$NC, "stn_lon")))
        }
        .self$.stn_lon[index]
    })


#' Retrieve the station lat locations
#'
#' @name DaymetStationsRefClass_stn_lat
#' @param index numeric, the indices to return
#' @return numeric vector of lat locations
DaymetStationsRefClass$methods(
    stn_lat = function(index = seq_len(.self$stns)){
        if (inherits(.self$.stn_lat, "uninitializedField")){
            .self$field(".stn_lat",
                        as.vector(ncdf4::ncvar_get(.self$NC, "stn_lat")))
        }
        .self$.stn_lat[index]
    })

#' Retrieve the dates
#'
#' @name DaymetStationsRefClass_dates
#' @return numeric vector of dates
DaymetStationsRefClass$methods(
    dates = function(){
        if (inherits(.self$.dates, "uninitializedField")){
            d <- .self$NC$dim$time$vals + as.Date("1980-01-01")
            .self$field(".dates",d)
        }
     .self$.dates
    })

#' Find the n closest stations to the lon/lat coordinates provided.
#'
#' @name DaymetStationsRefClass_closest_stations
#' @param lon numeric, the longitude locations
#' @param lat numeric, the latitude locations
#' @param n numeric, the number of stations to retrieve
#' @param longlat logical, if TRUE then find great circle distance. See
#'   \code{sp::spDistN1()}
#' @return tibble of the n closest stations with the following variables
#'  \itemize{
#'  \item{index the index of the station (order with station_id, station_name, etc)}
#'  \item{dist numeric, the distance in kilometers from station to requested point}
#'  }
DaymetStationsRefClass$methods(
    closest_stations = function(lon = -70.180833, lat = 43.799444,
                                n = 10,
                                longlat = TRUE){

        x <- .self$stnx()
        y <- .self$stny()
        lons <- .self$stn_lon()
        lats <- .self$stn_lat()
        if (longlat == FALSE) {
            xy <- points_transform(lon[1], lat[1],
                                   from_proj = get_crs("longlat"),
                                   to_proj   = get_crs("daymet"))
            d <- sp::spDistsN1(cbind(x,y), xy, longlat = FALSE)
        } else {
            d <- sp::spDistsN1(cbind(lons,lats), cbind(lon, lat), longlat = TRUE)
        }
        ix <- order(d)[seq_len(n)]
        dplyr::tibble(
            index = ix,
            dist  = d[ix],
            lat   = lats[ix],
            lon   = lons[ix])
    })


#' Get station data by station name, station id or index within resource.
#'
#' At least one of name, id or index must be provided.
#'
#' @name DaymetStationsRefClass_station_data
#' @param name character the station name
#' @param id character, if name is not provided then we try to match the station_id provided
#' @param index numeric, if name and id are not provided, then we use the index provided
#' @return tibble of zero or more rows of variables date, obs and pred data values
DaymetStationsRefClass$methods(
    station_data = function(name, id = NULL, index = 1){

        dummy <- dplyr::tibble(date = character(), obs = numeric(), pred = numeric())
        if (!missing(name)){
            nm <- .self$station_name()
            index <- which(nm %in% toupper(name[1]))
            if (length(index) == 0){
                message("no stations found of name", name[1])
                return(dummy)
            }
        } else if (!is.null(id)){
            ids <- .self$station_id()
            index <- which(ids %in% id[1])
            if (length(index) == 0){
                message("no stations found of id", id[1])
                return(dummy)
            }
        }

        dplyr::tibble(
                date = .self$dates(),
                obs  = as.vector(ncdf4::ncvar_get(.self$NC, "obs",
                                                  start = c(1,index[1]),
                                                  count = c(-1, 1))),
                pred  = as.vector(ncdf4::ncvar_get(.self$NC, "pred",
                                                  start = c(1,index[1]),
                                                  count = c(-1, 1)))
        )


    }
)


#' Establish a DaymetStationsRefClass object
#'
#' @export
#' @param uri the uri of the daymet stations resource
#' @return DaymetStationsRefClass object
DaymetStations<- function(uri = daymet_station_uri()){
    DaymetStationsRefClass$new(uri)
}
