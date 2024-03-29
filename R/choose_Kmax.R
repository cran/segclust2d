#' Internal Function for choosing optimal number of segment
#'
#' Choosing optimal number of segment using Marc Lavielle's method. From Emilie
#' Lebarbier. Method based on identifying breaks in the slope of the contrast.
#' @param J likelihood for each number of segment
#' @param S threshold for choosing the number of segment. See
#'   adehabitatLT::chooseseg
#' @param ... additional arguments
#' @return  a list with optimal number of segment and full data.frame of the
#'   calculus
#'
#' @export
#'

chooseseg_lavielle <- function(J, S=0.75, ...)
{
  Kmax <-  length(J)
  Kseq <-  seq_len(Kmax)
  Kmax <- length(Kseq)
  Jtild <-  (Kseq[Kmax]-Kseq[1]) * (J[Kmax]-J)/(J[Kmax]-J[1])+1
  D <- diff(diff(Jtild))
  if (length(which(D>=S))>0){
    Kh <- max(which(D>=S))+1
  }else {
    Kh <- 1
  }
  Kh <- Kseq[Kh]
  return(list("Kopt"= Kh, "lavielle"= D))
}


#' Finding best segmentation with a different threshold S
#'
#' Choosing optimal number of segment using Marc Lavielle's method. 
#' From Emilie Lebarbier. Method based on identifying 
#' breaks in the slope of the contrast.
#'
#' @param x \code{segmentation-class} object
#' @param S threshold for choosing the number of segment. See
#'   adehabitatLT::chooseseg
#' @return  the optimal number of segment given threshold S.
#'
#' @examples
#' 
#' \dontrun{
#' res.seg <- segmentation(df, coord.names = c("x","y"), Kmax = 30, lmin = 10)
#' # find the optimal number of segment according to Lavielle's criterium with a
#' # different threshold.
#' choose_kmax(res.seg, S = 0.60) 
#' }
#' @export
#'

choose_kmax <- function(x, S=0.75)
{
  J <- - x$likelihood$likelihood
  Kh <- chooseseg_lavielle(J,S)$Kopt
  return(Kh)
}
