% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/segTraj_neighborsbis.R
\name{neighborsbis}
\alias{neighborsbis}
\title{neighbors tests whether neighbors of point k,P can  be used to re-initialize
the EM algorithm and to improve the log-likelihood.}
\usage{
neighborsbis(
  kv.hull,
  x,
  L,
  k,
  param,
  P,
  lmin,
  eps,
  sameSigma = TRUE,
  pureR = FALSE
)
}
\arguments{
\item{kv.hull}{convex hull of likelihood}

\item{x}{the initial dataset}

\item{L}{the likelihood}

\item{k}{the points of interest}

\item{param}{param outputs of segmentation}

\item{P}{the number of class}

\item{lmin}{minimal size of the segment to be implemented}

\item{eps}{eps}

\item{sameSigma}{should segments have same variance ?}

\item{pureR}{should algorithm use only R functions or benefit from Rcpp
faster algorithm}
}
\value{
smoothing likelihood
}
\description{
neighbors tests whether neighbors of point k,P can  be used to re-initialize
the EM algorithm and to improve the log-likelihood.
}
