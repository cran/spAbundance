\name{predict.sfMsNMix}
\alias{predict.sfMsNMix}
\title{Function for prediction at new locations for spatial factor multi-species N-mixture models}

\description{
  The function \code{predict} collects posterior predictive samples for a set of new locations given an object of class `sfMsNMix`. Prediction is possible for both the latent abundance state as well as detection.
}

\usage{
\method{predict}{sfMsNMix}(object, X.0, coords.0, n.omp.threads = 1, 
        verbose = TRUE, n.report = 100, 
        ignore.RE = FALSE, type = 'abundance', 
        include.sp = TRUE, ...)
}

\arguments{

  \item{object}{an object of class sfMsNMix}

  \item{X.0}{the design matrix of covariates at the prediction locations. This should include a column of 1s for the intercept if an intercept is included in the model. If random effects are included in the abundance (or detection if \code{type = 'detection'}) portion of the model, the levels of the random effects at the new locations should be included as a column in the design matrix. The ordering of the levels should match the ordering used to fit the data in \code{sfMsNMix}. Columns should correspond to the order of how covariates were specified in the corresponding formula argument of \code{sfMsNMix}. Column names must match the names of the variables used to fit the model (for the intercept, use \code{'(Intercept)'}).}

  \item{coords.0}{the spatial coordinates corresponding to \code{X.0}. Note that \code{spOccupancy} assumes coordinates are specified 
  in a projected coordinate system.}

   \item{n.omp.threads}{a positive integer indicating
    the number of threads to use for SMP parallel processing. The package must
    be compiled for OpenMP support. For most Intel-based machines, we recommend setting
    \code{n.omp.threads} up to the number of hyperthreaded cores. 
    Note, \code{n.omp.threads} > 1 might not work on some systems.}

  \item{verbose}{if \code{TRUE}, model specification and progress of the 
    sampler is printed to the screen. Otherwise, nothing is printed to
    the screen.}
  
  \item{n.report}{the interval to report sampling progress.}

  \item{ignore.RE}{a logical value indicating whether to include unstructured random effects for prediction. If TRUE, random effects will be ignored and prediction will only use the fixed effects. If FALSE, random effects will be included in the prediction for both observed and unobserved levels of the random effect.}

    \item{type}{a quoted keyword indicating what type of prediction to produce. Valid keywords are 'abundance' to predict expected abundance and latent abundance values (this is the default), or 'detection' to predict detection probability given new values of detection covariates.}

    \item{include.sp}{a logical value used to indicate whether spatial random effects should be included in the predictions. By default, this is set to \code{TRUE}. If set to \code{FALSE}, predictions are given using the covariates and any unstructured random effects in the model. If \code{FALSE}, the \code{coords.0} argument is not required.}
  
  \item{...}{currently no additional arguments}

}

\note{
  When \code{ignore.RE = FALSE}, both sampled levels and non-sampled levels of random effects are supported for prediction. For sampled levels, the posterior distribution for the random effect corresponding to that level of the random effect will be used in the prediction. For non-sampled levels, random values are drawn from a normal distribution using the posterior samples of the random effect variance, which results in fully propagated uncertainty in predictions with models that incorporate random effects.
}

\author{
  Jeffrey W. Doser \email{doserjef@msu.edu}, \cr
  Andrew O. Finley \email{finleya@msu.edu}
}

\value{
  A list object of class \code{predict.sfMsNMix}. When \code{type = 'abundance'}, the list consists of:  

  \item{mu.0.samples}{a three-dimensional array of posterior predictive samples for the
    expected abundance values. Note these will be per unit area if an offset was used when 
    fitting the model with \code{sfMsNMix()}.}

  \item{N.0.samples}{a three-dimensional array of posterior predictive samples for the
    latent abundance values. These will be in the same units as \code{mu.0.samples}.}

  \item{w.0.samples}{a three-dimensional array of posterior predictive samples for the
    spatial latent factors.}

  When \code{type = 'detection'}, the list consists of: 

  \item{p.0.samples}{a three-dimensional array of posterior predictive samples for the 
    detection probability values.}

  The return object will include additional objects used for standard 
  extractor functions. 
}

\examples{
set.seed(400)
J.x <- 8
J.y <- 8
J <- J.x * J.y
n.rep<- sample(2:4, size = J, replace = TRUE)
n.sp <- 6
# Community-level covariate effects
# Abundance
beta.mean <- c(0.2, 0.5)
p.abund <- length(beta.mean)
tau.sq.beta <- c(0.6, 0.3)
# Detection
alpha.mean <- c(0.5, 0.2, -0.1)
tau.sq.alpha <- c(0.2, 0.3, 1)
p.det <- length(alpha.mean)
# Draw species-level effects from community means.
beta <- matrix(NA, nrow = n.sp, ncol = p.abund)
alpha <- matrix(NA, nrow = n.sp, ncol = p.det)
for (i in 1:p.abund) {
  beta[, i] <- rnorm(n.sp, beta.mean[i], sqrt(tau.sq.beta[i]))
}
for (i in 1:p.det) {
  alpha[, i] <- rnorm(n.sp, alpha.mean[i], sqrt(tau.sq.alpha[i]))
}
family <- 'Poisson'
n.factors <- 3
phi <- runif(n.factors, 3 / 1, 3 / .1)

dat <- simMsNMix(J.x = J.x, J.y = J.y, n.rep = n.rep, n.sp = n.sp, 
                 beta = beta, alpha = alpha, sp = TRUE, 
                 family = 'Poisson', factor.model = TRUE, 
                 n.factors = n.factors, phi = phi, cov.model = 'exponential')
# Split into fitting and prediction data set
pred.indx <- sample(1:J, round(J * .25), replace = FALSE)
y <- dat$y[, -pred.indx, ]
# Abundance covariates
X <- dat$X[-pred.indx, ]
# Detection covariates
X.p <- dat$X.p[-pred.indx, , ]
# Coordinates
coords <- dat$coords[-pred.indx, ]
# Prediction values
X.0 <- dat$X[pred.indx, ]
mu.0 <- dat$psi[, pred.indx]
coords.0 <- dat$coords[pred.indx, ]
# Package all data into a list
abund.covs <- X[, 2, drop = FALSE]
colnames(abund.covs) <- c('abund.cov')
det.covs <- list(det.cov.1 = X.p[, , 2], 
                 det.cov.2 = X.p[, , 3])
data.list <- list(y = y, 
                  abund.covs = abund.covs,
                  det.covs = det.covs, 
                  coords = coords)

# Initial values
prior.list <- list(beta.comm.normal = list(mean = 0, var = 2.72), 
                   alpha.comm.normal = list(mean = 0, var = 2.72), 
                   tau.sq.beta.ig = list(a = 0.1, b = 0.1), 
                   tau.sq.alpha.ig = list(a = 0.1, b = 0.1), 
                   phi.unif = list(a = 3 / 1, 3 / .1))
# Initial values
inits.list <- list(alpha.comm = 0, 
                   beta.comm = 0, 
                   beta = 0, 
                   alpha = 0,
                   phi = 3 / .5,
                   tau.sq.beta = 1, 
                   tau.sq.alpha = 1, 
                   N = apply(y, c(1, 2), max, na.rm = TRUE))
# Tuning values
tuning <- list(beta = 0.3, alpha = 0.3, lambda = 0.5, w = 0.5, phi = 1.5)
n.batch <- 4
batch.length <- 25
accept.rate <- 0.43

out <- sfMsNMix(abund.formula = ~ abund.cov, 
                det.formula = ~ det.cov.1 + det.cov.2, 
                data = data.list, 
                inits = inits.list, 
                family = 'Poisson', 
                n.factors = n.factors,
                n.batch = n.batch,
                batch.length = batch.length, 
                accept.rate = 0.43,
                cov.model = 'exponential', 
                n.neighbors = 5,
                tuning = tuning,
                priors = prior.list, 
                n.omp.threads = 1, 
                verbose = TRUE, 
                n.report = 1)

summary(out, level = 'community')

# Predict at new locations ------------------------------------------------
out.pred <- predict(out, X.0, coords.0)
str(out.pred)
}

