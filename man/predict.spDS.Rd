\name{predict.spDS}
\alias{predict.spDS}
\title{Function for prediction at new locations for single-species spatially-explicit hierarchical distance sampling models}

\description{
  The function \code{predict} collects posterior predictive samples for a set of new locations given an object of class `spDS`. Prediction is possible for both the latent abundance state as well as detection. 
}

\usage{
\method{predict}{spDS}(object, X.0, coords.0, n.omp.threads = 1, 
        verbose = TRUE, n.report = 100, ignore.RE = FALSE, 
        type = 'abundance', include.sp = TRUE, ...)
}

\arguments{

  \item{object}{an object of class spDS}

  \item{X.0}{the design matrix of covariates at the prediction locations. This should include a column of 1s for the intercept if an intercept is included in the model. If random effects are included in the abundance (or detection if \code{type = 'detection'}) portion of the model, the levels of the random effects at the new locations should be included as a column in the design matrix. The ordering of the levels should match the ordering used to fit the data in \code{spDS}. Columns should correspond to the order of how covariates were specified in the corresponding formula argument of \code{spDS}. Column names of all variables must match the names of variables used when fitting the model (for the intercept, use \code{'(Intercept)'}).}

  \item{coords.0}{the spatial coordinates corresponding to \code{X.0}. Note that \code{spAbundance} assumes coordinates are specified 
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

  \item{ignore.RE}{logical value that specifies whether or not to remove random abundance (or detection if \code{type = 'detection'}) effects from the subsequent predictions. If \code{TRUE}, random effects will be included. If \code{FALSE}, random effects will be set to 0 and predictions will only be generated from the fixed effects.}

  \item{type}{a quoted keyword indicating what type of prediction to produce. Valid keywords are 'abundance' to predict latent abundance and expected abundance values (this is the default), or 'detection' to predict detection probability given new values of detection covariates.}

    \item{include.sp}{a logical value used to indicate whether spatial random effects should be included in the predictions. By default, this is set to \code{TRUE}. If set to \code{FALSE}, predictions are given using the covariates and any unstructured random effects in the model. If \code{FALSE}, the \code{coords} argument is not required.}

  \item{...}{currently no additional arguments}
}

\note{
  When \code{ignore.RE = FALSE}, both sampled levels and non-sampled levels of random effects are supported for prediction. For sampled levels, the posterior distribution for the random intercept corresponding to that level of the random effect will be used in the prediction. For non-sampled levels, random values are drawn from a normal distribution using the posterior samples of the random effect variance, which results in fully propagated uncertainty in predictions with models that incorporate random effects. 
}

\author{
  Jeffrey W. Doser \email{doserjef@msu.edu}, \cr
  Andrew O. Finley \email{finleya@msu.edu}, \cr
}

\value{
  A list object of class \code{predict.spDS}. When \code{type = 'abundance'}, the list consists of: 

  \item{mu.0.samples}{a \code{coda} object of posterior predictive samples for the
    expected abundance values, or expected abundance per unit area (i.e., density) values
    when an offset was used when fitting the model with \code{spDS()}.}

  \item{N.0.samples}{a \code{coda} object of posterior predictive samples for the
    latent abundance values. These will be in the same units as \code{mu.0.samples}}

  \item{w.0.samples}{a \code{coda} object of posterior predictive samples 
    for the latent spatial random effects.}

  When \code{type = 'detection'}, the list consists of: 

  \item{sigma.0.samples}{a \code{coda} object of posterior predictive samples for sigma 
  (the parameter controlling detection probability).}

  The return object will include additional objects used for standard 
  extractor functions. 
}

\examples{
set.seed(123)
J.x <- 10
J.y <- 10 
J <- J.x * J.y
# Number of distance bins from which to simulate data. 
n.bins <- 5
# Length of each bin. This should be of length n.bins
bin.width <- c(.10, .10, .20, .3, .1)
# Abundance coefficients
beta <- c(1.0, 0.2, 0.3, -0.2)
p.abund <- length(beta)
# Detection coefficients
alpha <- c(-1.0, -0.3)
p.det <- length(alpha)
# Detection decay function
det.func <- 'halfnormal'
mu.RE <- list()
p.RE <- list()
sp <- TRUE
phi <- 3 / .5
sigma.sq <- 0.8
cov.model <- 'exponential'
family <- 'NB'
kappa <- 0.1
offset <- 1.8
transect <- 'point'

dat <- simDS(J.x = J.x, J.y = J.y, n.bins = n.bins, bin.width = bin.width,
             beta = beta, alpha = alpha, det.func = det.func, kappa = kappa, 
             mu.RE = mu.RE, p.RE = p.RE, sp = sp, family = family, 
             offset = offset, transect = transect, phi = phi, sigma.sq = sigma.sq,
             cov.model = cov.model)
# Split into fitting and prediction data set
pred.indx <- sample(1:J, round(J * .25), replace = FALSE)
y <- dat$y[-pred.indx, ]
# Abundance covariates
X <- dat$X[-pred.indx, ]
# Prediction covariates
X.0 <- dat$X[pred.indx, ]
# Detection covariates
X.p <- dat$X.p[-pred.indx, ]
dist.breaks <- dat$dist.breaks
coords <- dat$coords[-pred.indx, ]
coords.0 <- dat$coords[pred.indx, ]

covs <- cbind(X, X.p)
colnames(covs) <- c('int.abund', 'abund.cov.1', 'abund.cov.2', 'abund.cov.3', 
                    'int.det', 'det.cov.1')

data.list <- list(y = y, 
                  covs = covs,
                  dist.breaks = dist.breaks, 
                  coords = coords,
                  offset = offset)

# Priors
prior.list <- list(beta.normal = list(mean = 0, var = 10),
                   alpha.normal = list(mean = 0,
                                       var = 10), 
                   kappa.unif = c(0, 100), 
                   phi.unif = c(3 / 1, 3 / .1),
                   sigma.sq.ig = c(2, 1)) 
# Starting values
inits.list <- list(alpha = 0,
                   beta = 0,
                   kappa = 1, 
                   phi = 3 / .5, 
                   sigma.sq = 1)
# Tuning values
tuning <- list(beta = 0.1, alpha = 0.1, beta.star = 0.3, alpha.star = 0.1, 
               kappa = 0.2, phi = 1, w = 1) 

out <- spDS(abund.formula = ~ abund.cov.1 + abund.cov.2 + abund.cov.3,
            det.formula = ~ det.cov.1,
            data = data.list, 
            n.batch = 10, 
            batch.length = 25, 
            inits = inits.list, 
            family = 'NB',
            det.func = 'halfnormal', 
            transect = 'point', 
            cov.model = 'exponential', 
            NNGP = TRUE,
            n.neighbors = 5,
            tuning = tuning,
            priors = prior.list, 
            accept.rate = 0.43, 
            n.omp.threads = 1, 
            verbose = TRUE, 
            n.report = 100,
            n.burn = 100,
            n.thin = 1,
            n.chains = 1) 
summary(out)

# Predict at new locations ------------------------------------------------
colnames(X.0) <- c('intercept', 'abund.cov.1', 'abund.cov.2', 'abund.cov.3')
out.pred <- predict(out, X.0, coords.0)
mu.0.quants <- apply(out.pred$mu.0.samples, 2, quantile, c(0.025, 0.5, 0.975))
plot(dat$mu[pred.indx], mu.0.quants[2, ], pch = 19, xlab = 'True', 
     ylab = 'Fitted', ylim = c(min(mu.0.quants), max(mu.0.quants)))
segments(dat$mu[pred.indx], mu.0.quants[1, ], dat$mu[pred.indx], mu.0.quants[3, ])
lines(dat$mu[pred.indx], dat$mu[pred.indx])
}
