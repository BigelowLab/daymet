% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ncss.R
\name{ncss_base_url}
\alias{ncss_base_url}
\title{Generate a NCSS url for the given year, variable and region}
\usage{
ncss_base_url(
  year = format(Sys.Date() - 365, "\%Y"),
  var = "dayl",
  region = "na",
  version = daymet_version(),
  root = ncss_root_url()
)
}
\arguments{
\item{year}{character or numeric, 4 digit year to access}

\item{var}{character, the variable name}

\item{region}{character, the name of the region (default 'na')}

\item{version}{character, "v4"}

\item{root}{character, the root URL}
}
\value{
the base url
}
\description{
Generate a NCSS url for the given year, variable and region
}
