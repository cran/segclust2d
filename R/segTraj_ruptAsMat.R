# ruptAsMat 
#' ruptAsMat is an internal function to transform a vector giving the change
#' point to matrix 2 columns matrix in which each line gives the beginning and
#' the end of a segment
#' @param vectRupt the vector of change point
#' @return the matrix containing the segments
#' 
ruptAsMat <- function(vectRupt)
{
  vectRupt <- vectRupt[vectRupt>0]
  K <- length(vectRupt)-1
  mat <- matrix(c(c(1,vectRupt[1:K]+1),vectRupt[1:(K+1)] ), ncol=2)
  return(mat)
}
