% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/choose_Kmax.R
\name{choose_kmax}
\alias{choose_kmax}
\title{Finding best segmentation with a different threshold S}
\usage{
choose_kmax(x, S = 0.75)
}
\arguments{
\item{x}{\code{segmentation-class} object}

\item{S}{threshold for choosing the number of segment. See
adehabitatLT::chooseseg}
}
\value{
the optimal number of segment given threshold S.
}
\description{
Choosing optimal number of segment using Marc Lavielle's method. 
From Emilie Lebarbier. Method based on identifying 
breaks in the slope of the contrast.
}
\examples{

\dontrun{
res.seg <- segmentation(df, coord.names = c("x","y"), Kmax = 30, lmin = 10)
# find the optimal number of segment according to Lavielle's criterium with a
# different threshold.
choose_kmax(res.seg, S = 0.60) 
}
}
