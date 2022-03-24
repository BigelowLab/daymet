library(ncdf4)
cat("nc_version:", nc_version(), "\n")
# nc_version: ncdf4_1.19_20211214 

uri <- "https://thredds.daac.ornl.gov/thredds/dodsC/ornldaac/1840/daymet_v4_daily_na_tmin_2018.nc"
X <- nc_open(uri)


x <- ncvar_get(X, varid = "tmin", start = c(1,1,1), count = c(1,1, 1))


x <- ncvar_get(X, varid = "tmin", start = c(1,1,1), count = c(-1,-1, 1))
# Error in Rsx_nc4_get_vara_double: NetCDF: Access failure
# Var: tmin  Ndims: 3   Start: 0,0,0 Count: 1,8075,7814
# Error in ncvar_get_inner(ncid2use, varid2use, nc$var[[li]]$missval, addOffset,  : 
#                            C function R_nc4_get_vara_double returned error

nc_close(X)

uri2 <- "http://oceandata.sci.gsfc.nasa.gov/opendap/MODISA/L3SMI/2021/001/A2021001.L3m_DAY_CHL_chl_ocx_4km.nc"
X = nc_open(uri2)
x <- ncvar_get(X, varid = "chl_ocx", start = c(1,1), count = c(-1,-1))


# > sessionInfo()
# R version 4.1.2 (2021-11-01)
# Platform: x86_64-redhat-linux-gnu (64-bit)
# Running under: Rocky Linux 8.5 (Green Obsidian)
# 
# Matrix products: default
# BLAS/LAPACK: /usr/lib64/libopenblas-r0.3.12.so
# 
# locale:
#   [1] LC_CTYPE=en_US.UTF-8       LC_NUMERIC=C              
# [3] LC_TIME=en_US.UTF-8        LC_COLLATE=en_US.UTF-8    
# [5] LC_MONETARY=en_US.UTF-8    LC_MESSAGES=en_US.UTF-8   
# [7] LC_PAPER=en_US.UTF-8       LC_NAME=C                 
# [9] LC_ADDRESS=C               LC_TELEPHONE=C            
# [11] LC_MEASUREMENT=en_US.UTF-8 LC_IDENTIFICATION=C       
# 
# attached base packages:
#   [1] stats     graphics  grDevices utils     datasets  methods   base     
# 
# other attached packages:
#   [1] ncdf4_1.19
# 
# loaded via a namespace (and not attached):
#   [1] compiler_4.1.2  tools_4.1.2     rstudioapi_0.13
