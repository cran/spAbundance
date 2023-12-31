\name{predict.lfMsAbund}
\alias{predict.lfMsAbund}
\title{Function for prediction at new locations for latent factor multivariate GLMMs}

\description{
  The function \code{predict} collects posterior predictive samples for a set of new locations given an object of class `lfMsAbund`.  
}

\usage{
\method{predict}{lfMsAbund}(object, X.0, coords.0, ignore.RE = FALSE, z.0.samples, include.w = TRUE, ...)
}

\arguments{

  \item{object}{an object of class lfMsAbund}

  \item{X.0}{the design matrix of covariates at the prediction locations. This can be either a two-dimensional matrix with rows corresponding to sites and columns corresponding to covariates, or can be a three-dimensional array, with dimensions corresponding to site, replicate, and covariate, respectively. Note that the first covariate should consist of all 1s for the intercept if an intercept is included in the model. If random effects are included in the the model, the levels of the random effects at the new locations/time periods should be included as an element of the three-dimensional array. The ordering of the levels should match the ordering used to fit the data in \code{lfMsAbund}. The covariates should be organized in the same order as they were specified in the corresponding formula argument of \code{lfMsAbund}. Names of the third dimension (covariates) of any random effects in X.0 must match the name of the random effects used to fit the model, if specified in the corresponding formula argument of \code{lfMsAbund}. See example below.}

  \item{coords.0}{the spatial coordinates corresponding to \code{X.0}. 
    Note that \code{spOccupancy} assumes coordinates are specified 
    in a projected coordinate system.}

  \item{ignore.RE}{logical value that specifies whether or not to remove unstructured random effects from the subsequent predictions. If \code{TRUE}, unstructured random effects will be included. If \code{FALSE}, unstructured random effects will be set to 0 and predictions will only be generated from the fixed effects.}

  \item{z.0.samples}{a three-dimensional array with dimensions corresponding to MCMC samples, species, and prediction locations. The array contains the full posterior samples of the predicted binary portion of a Gaussian zero-inflated model. In the context of abundance models, this typically corresponds to estimates of the presence or absence of each species at the location. When using \code{spOccupancy} to generate the first stage samples of the zi-Gaussian model, this is the object contained in the \code{z.0.samples} object of the predition function for the spOccupancy object. Ignored for all model types other than zi-Gaussian.}

    \item{include.w}{a logical value used to indicate whether the latent random effects should be included in the predictions. By default, this is set to \code{TRUE}. If set to \code{FALSE}, predictions are given using the covariates and any unstructured random effects in the model. If \code{FALSE}, the \code{coords.0} argument is not required.}

  \item{...}{currently no additional arguments}
}

\note{
  When \code{ignore.RE = FALSE}, both sampled levels and non-sampled levels of random effects are supported for prediction. For sampled levels, the posterior distribution for the random effect corresponding to that level of the random effect will be used in the prediction. For non-sampled levels, random values are drawn from a normal distribution using the posterior samples of the random effect variance, which results in fully propagated uncertainty in predictions with models that incorporate random effects. 
}

\author{
  Jeffrey W. Doser \email{doserjef@msu.edu}, \cr
}

\value{
  A list object of class \code{predict.lfMsAbund}. The list consists of: 

  \item{mu.0.samples}{a three or four-dimensional object of posterior predictive samples for the
    expected abundance values with dimensions corresponding to posterior predictive
    sample, species, site, and replicate. Note if an offset was used when fitting the model
    with \code{lfMsAbund}, the abundance values are reported per unit of the offset.}

  \item{y.0.samples}{a three or four-dimensional object of posterior predictive samples for the
    abundance values with dimensions corresponding to posterior predictive sample, species, site, 
    and replicate. These will be in the same units as \code{mu.0.samples}.}

  \item{w.0.samples}{a three-dimensional array of posterior predictive samples for the
    latent factors.}

  The return object will include additional objects used for standard 
  extractor functions. 
}

\examples{
set.seed(408)
J.x <- 8
J.y <- 8
J <- J.x * J.y
n.rep <- sample(3, size = J, replace = TRUE)
n.sp <- 6
# Community-level covariate effects
beta.mean <- c(-2, 0.5)
p.abund <- length(beta.mean)
tau.sq.beta <- c(0.2, 1.2)
mu.RE <- list()
# Draw species-level effects from community means.
beta <- matrix(NA, nrow = n.sp, ncol = p.abund)
for (i in 1:p.abund) {
  beta[, i] <- rnorm(n.sp, beta.mean[i], sqrt(tau.sq.beta[i]))
}
sp <- FALSE
kappa <- runif(n.sp, 0.1, 1)
factor.model <- TRUE
n.factors <- 3

dat <- simMsAbund(J.x = J.x, J.y = J.y, n.rep = n.rep, n.sp = n.sp, beta = beta,
                  mu.RE = mu.RE, sp = sp, kappa = kappa, family = 'NB', 
                  factor.model = factor.model, n.factors = n.factors)

# Split into fitting and prediction data set
pred.indx <- sample(1:J, round(J * .25), replace = FALSE)
y <- dat$y[, -pred.indx, , drop = FALSE]
# Occupancy covariates
X <- dat$X[-pred.indx, , , drop = FALSE]
# Coordinates
coords <- dat$coords[-pred.indx, ]
# Prediction values
y.0 <- dat$y[, pred.indx, , drop = FALSE]
X.0 <- dat$X[pred.indx, , , drop = FALSE]
coords.0 <- dat$coords[pred.indx, ]

# Package all data into a list
covs <- list(int = X[, , 1],
             abund.cov.1 = X[, , 2])
data.list <- list(y = y, covs = covs, coords = coords)
prior.list <- list(beta.comm.normal = list(mean = 0, var = 100),
                   kappa.unif = list(a = 0, b = 10),
                   tau.sq.beta.ig = list(a = .1, b = .1))
inits.list <- list(beta.comm = 0,
                   beta = 0,
                   kappa = 0.5,
                   tau.sq.beta = 1)
tuning.list <- list(kappa = 0.3, beta = 0.1, lambda = 0.5, w = 0.5)

# Small
n.batch <- 2
batch.length <- 25
n.burn <- 20
n.thin <- 1
n.chains <- 1

out <- lfMsAbund(formula = ~ abund.cov.1,
                 data = data.list,
                 n.batch = n.batch,
                 inits = inits.list,
                 priors = prior.list,
                 tuning = tuning.list,
                 batch.length = batch.length,
                 n.omp.threads = 1,
                 n.factors = 1,
                 verbose = TRUE,
                 n.report = 1,
                 n.burn = n.burn,
                 n.thin = n.thin,
                 n.chains = n.chains)

# Predict at new locations
out.pred <- predict(out, X.0, coords.0)
str(out.pred)
}
