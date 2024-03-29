# hybrid_simultanee
#' \code{hybrid_simultanee} performs a simultaneous seg - clustering for
#' bivariate signals.
#'
#' It is an algorithm which combines dynamic programming
#' and the EM algorithm to calculate the MLE of phi and T, which
#' are the mixture parameters and the change point instants.
#' this algorithm is run for a given number of clusters,
#' and estimates the parameters for a segmentation/clustering
#' model with P clusters and 1:Kmax segments
#'
#' @param x the two-dimensional signal, one line per dimension
#' @param P the number of classes
#' @param Kmax the maximal number of segments
#' @param lmin minimum length of segment
#' @param sameSigma should segment have the same variance
#' @param sameVar.init sameVar.init
#' @param eps eps
#' @param lissage should likelihood be smoothed
#' @param pureR should algorithm run in full R or use Rcpp speed improvements
#' @param ... additional parameters
#' @return  a list with Linc, the incomplete loglikelihood =Linc,param=paramtau
#'   posterior probability
#
#' @useDynLib segclust2d, .registration=TRUE
#' @importFrom Rcpp sourceCpp

hybrid_simultanee <- function(x, P, Kmax, lmin = 3,
                              sameSigma = TRUE, sameVar.init = FALSE, 
                              eps = 1e-6, lissage = TRUE,
                              pureR = FALSE, ...) {
  Linc <- matrix(-Inf, nrow = Kmax, ncol = 1)
  n <- dim(x)[2]
  param <- list()
  Kmin <- P

  if (P == 1) {
    rupt <- c(1, n)
    phi <- list(mu = matrix(rowMeans(x), ncol = 1),
                sigma = matrix(apply(x, 1, stats::sd), ncol = 1), 
                prop = 1)
    Linc[Kmin:Kmax] <- logdens_simultanee(x, phi)
    param[[1]] <- list(phi = phi, rupt = rupt)

    # phi contains means, standard-deviation and
    # proportions for each component of the mixture
    
  } else {
    
    # Rq: lmin=5 for the initialization step because of the hierarchical
    # clustering
    hybrid_sb <- cli::cli_status(
      "{cli::symbol$arrow_right} Calculating initial \\
      segmentation without clustering")
    
    G <- Gmean_simultanee(x, 5, sameVar = sameVar.init)
    out <- DynProg(G, Kmax = Kmax)

    # message("Segmenting - ", P, " class")
    
    for (K in Kmin:Kmax) {
      # cli_progress_update()
      cli::cli_status_update(
        id = hybrid_sb,
        "{cli::symbol$arrow_right} Segmentation-Clustering for \\
        ncluster = {P} and nseg = {K}/{Kmax}")
      
      j <- 0
      delta <- Inf
      empty <- 0
      dv <- 0
      th <- out$t.est[K, 1:K]
      rupt <- matrix(ncol = 2, c(c(1, th[1:(K - 1)] + 1), th))
      phi <- EM.init_simultanee(x, rupt, K, P)
      if (pureR) {
        out.EM <- EM.algo_simultanee(x, rupt, P, phi, eps, sameSigma)
      } else {
        out.EM <- EM.algo_simultanee_Cpp(x, rupt, P, phi, eps, sameSigma)
      }
      phi <- out.EM$phi
      tau <- out.EM$tau
      #  bisig_plot(x, rupt = rupt)
      lvCurrent <- out.EM$lvinc
      improveLv <- TRUE
      while ( (delta > 1e-4 | is.nan(delta)) & 
              (empty == 0) & 
              (dv == 0) &
              (j <= 100) &
              improveLv) {
        #       while ( (delta>1e-4 | is.nan(delta)) & (empty==0) & (dv==0) &
        #       (j<=100)){
        j <- j + 1
        # cat(j)
        phi.temp <- phi
        if (pureR) {
          G <- Gmixt_simultanee(x, lmin = lmin, phi.temp)
          out.DP <- DynProg(G, K)
        } else {
          G <- Gmixt_simultanee_fullcpp(x, 
                                        lmin = lmin,
                                        phi.temp$prop, 
                                        phi.temp$mu,
                                        phi.temp$sigma)
          out.DP <- wrap_dynprog_cpp(G, K)
        }
        # if(K == 8) browser()
        t.est <- out.DP$t.est

        #      G          = Gmixt_simultaneeF(x,lmin=2,phi.temp,P)
        #      out.DP     = DynProg(G,K)
        #      t.est      = out.DP$t.est
        #      J.est      = out.DP$J.est

        rupt <- ruptAsMat(t.est[K, ])

        if (pureR) {
          out.EM <- EM.algo_simultanee(x, rupt, P, phi.temp, eps, sameSigma)
        } else {
          out.EM <- EM.algo_simultanee_Cpp(x, rupt, P, phi.temp, eps, sameSigma)
        }
        phi <- out.EM$phi
        tau <- out.EM$tau
        empty <- out.EM$empty
        dv <- out.EM$dv
        lvinc.mixt <- out.EM$lvinc
        improveLv <- (lvinc.mixt > lvCurrent)
        lvCurrent <- ifelse(improveLv, lvinc.mixt, lvCurrent)
        #  bisig_plot(x, rupt = rupt)
        delta <- max(unlist(lapply(names(phi), function(d) {
          max(abs(phi.temp[[d]] - phi[[d]]) / phi[[d]])
        })))
      } # end while



      Linc[K] <- lvinc.mixt
      param[[K]] <- list(phi = phi, rupt = rupt, tau = tau, 
                         cluster = apply(tau, 1, which.max))
    } # end K
  }

  # smoothing likelihood ----------------------------------------------------




  #
  #   Ltmp= rep(-Inf,Kmax)
  #   cat("tracking local maxima for P =",P,"\n")
  #
  #   while (sum(Ltmp!=Linc)>=1) {
  #     #    # find the convex hull of the likelihood
  #     Ltmp     = Linc
  #     kvfinite = which(is.finite(Linc[(P):Kmax]))+P-1
  #     Lfinite  = Linc[kvfinite]
  #     a        = chull(x=kvfinite, y=Lfinite)
  #     a        = kvfinite[a]
  #     oumin    = which(a==(Kmin))
  #     oumax    = which(a==(Kmax))
  #     a        = a[oumin:oumax]
  #     kvfinite = sort(a)
  #     # find the coordinates of points out of the convex hull
  #     Kconc    = c(1:Kmax)
  #     Kconc    = Kconc[-which(Kconc %in% c(kvfinite))]
  #     Kconc    = Kconc[Kconc>=Kmin]
  #
  #     for (k in Kconc){
  #
  #       out.neighbors  = neighbors(x=x, L=Linc,k=k,param=param,P=P,lmin=lmin,
  #       eps,sameSigma)
  #       param          = out.neighbors$param
  #       Linc           = out.neighbors$L
  #       #plot(1:length(Linc),Linc,col=1)     lines(1:length(Ltmp),Ltmp,col=2)
  #       lines(k,Linc[k],col=3)
  #
  #     } # end k
  #
  #     out.neighbors  = neighbors(x=x, L=Linc,k=Kmax,param=param,P=P,lmin=lmin,
  #     eps,sameSigma)
  #     param          = out.neighbors$param
  #     Linc          = out.neighbors$L
  #
  #   } # end while
  #
  #
  cli::cli_alert_success(
    "Segmentation-Clustering successful \\
    for ncluster = {P} and nseg = {P}:{Kmax}")
  
  if (lissage) {
    cli::cli_status_update(
      id = hybrid_sb,
      "{cli::symbol$arrow_right} Smoothing likelihood for \\
        ncluster = {P}. This step can be lengthy.")

    # message("Smoothing  - ", P, " class")
    Ltmp <- rep(-Inf, Kmax)
    # graphics::plot(1:length(Linc),Linc,col=1)
    # cat("tracking local maxima for P =",P,"\n")

    while (sum(Ltmp != Linc) >= 1) {
      #    # find the convex hull of the likelihood
      Ltmp <- Linc
      kvfinite <- which(is.finite(Linc))
      Lfinite <- Linc[kvfinite]
      Kmax.max <- which.max(Linc)
      Lfinite <- Lfinite[kvfinite <= Kmax.max]
      kvfinite <- kvfinite[kvfinite <= Kmax.max]
      a <- grDevices::chull(x = kvfinite, y = Lfinite)
      a <- kvfinite[sort(a)]
      if (length(a) >= 3) {
        rg <- which(-diff(diff(Linc[a]) / diff(a)) < 0)
        if (length(rg) >= 1) {
          a <- a[-(rg + 1)]
        }
      }
      #######
      #     a        = kvfinite[sort(a)]
      #     rg       = which(diff(Linc[a])<0)
      #     if (length(rg)>=1){
      #       a        = a[-(rg+1)]
      #       Lfinite  = Lfinite[-(rg+1)]
      # }

      # kvfinitebis= sort(which(is.finite(Linc)))
      # find the coordinates of points out of the convex hull
      Kconc <- c(Kmin:Kmax)
      Kconc <- Kconc[-which(Kconc %in% a)]

      # neighbors = convex hull / max on Left, max on Right, first left, first
      # right (on the finite set)
      # neighborsbis = convex hull and only the increasing part / loop on the
      # resulting dimensions for all the others dimensions
      # neighborster = convex hull and only the increasing part / first left and
      # first right for all the others dimensions

      for (k in Kconc) {
        # out.neighbors  = neighbors(x=x, L=Linc,k=k,param=param,P=P,lmin=lmin,
        # eps,sameSigma) out.neighbors  = neighborsbis(kvfinite,x,
        # L=Linc,k=k,param=param,P=P,lmin=lmin, eps,sameSigma) out.neighbors  =
        # neighborster(kvfinite,x, L=Linc,k=k,param=param,P=P,lmin=lmin,
        # eps,sameSigma)

        #  rg.k=which(kvfinitebis==k)
        #  if (length(rg.k)==1){
        #    kvfinitebis.liste=kvfinitebis[-rg.k]
        #  } else {
        #    kvfinitebis.liste=kvfinitebis
        #  }
        #  out.neighbors  = neighborsbis(kvfinitebis.liste,x,
        #  L=Linc,k=k,param=param,P=P,lmin=lmin, eps,sameSigma)
        out.neighbors <- neighborsbis(a, x, L = Linc, k = k,
                                      param = param, P = P, 
                                      lmin = lmin, eps, 
                                      sameSigma, pureR = pureR)

        param <- out.neighbors$param
        Linc <- out.neighbors$L
        # graphics::lines(1:length(Ltmp),Ltmp,col=2)
      } # end k
      # out.neighbors  = neighbors(x=x, L=Linc,k=Kmax,
      #                            param=param,P=P,
      #                            lmin=lmin, eps,sameSigma)
      # param          = out.neighbors$param
      # Linc           = out.neighbors$L
      # lines(1:length(Ltmp),Ltmp,col=2)
    } # end while
    cli::cli_alert_success(
      "Smoothing successful \\
    for ncluster = {P}")
    
  }
  cli::cli_status_clear(id = hybrid_sb)
  
  invisible(list(Linc = Linc, param = param))
} # end function
