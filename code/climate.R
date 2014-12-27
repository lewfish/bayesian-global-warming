library(ncdf)
library(R2jags)
library(ggplot2)
library(ggmap)

## options(error=recover)

fn.stem <- "../paper/figs"
make.fn <- function(name) {
  sprintf("%s/%s", fn.stem, name)
}

## in ESS (emacs speaks statistiscs), comments starting with ##
## are tab-aligned with the enclosing block

## load data from GIS Temp data set
## file from http://data.giss.nasa.gov/pub/gistemp/gistemp1200_ERSST.nc.gz
ncdf.data <- open.ncdf("../data/gistemp1200_ERSST.nc")
raw.temps <- get.var.ncdf(ncdf.data, "tempanomaly")

## return vector of yearly temp anomalies for a location
getTemps <- function(lon,  # in [-180, 180]
                     lat,  # in [-90, 90]
                     temps,  # 3D array with dims=(lon, lat, monthly temp anomalies)
                     n.years  # number of years going backwards
                     ) {
    ## divide by 2 because each time series is for a 2 degree cell
    lon.ind <- (lon + 180) %/% 2
    lat.ind <- (lat + 90) %/% 2
    n.months <- dim(temps)[3]
    
    ## don't use the extra.months at the beginning of the time series
    monthly.temps <- temps[lon.ind,
                           lat.ind,
                           (n.months - n.years * 12 + 1) : n.months]
    monthly.temps <- as.vector(monthly.temps)
    yearlyMeans(monthly.temps)
}

## return yearly means
yearlyMeans <- function(monthly  # monthly is a vector of monthly temps
                        ) {
    n.months <- length(monthly)
    n.years <- n.months / 12
    ## reshape into a matrix, where cols are years and rows are months
    ## note: matrices are filled in col-major order
    monthly <- matrix(monthly, nrow = 12, ncol = n.years)
    ## get the mean of the columns, so we have the yearly mean
    yearly <- colMeans(monthly)
    yearly
}

## just use the past 50 years even though there are 134 years in the data
n.years <- 50

## generate 6x6 grid of lats and lons over eurasia/africa
lats <- seq(-35, 65, length.out=6)
lons <- seq(-10, 150, length.out=6)
n.regions <- length(lons) * length(lats)
## init n.years x n.regions matrix with zeros
temps.mat <- matrix(0, n.years, n.regions)
region <- 1
region.labels <- rep(0, n.regions)
for(lat in lats) {
    for(lon in lons) {
        region.labels[region] <- sprintf("(%d,%d)", lat, lon)
        temps.mat[, region] <- getTemps(lon, lat, raw.temps, n.years)
        region <- region + 1
    }
}

## plot temp anomaly data
temps.vect <- as.vector(temps.mat)  # all temps grouped by region
times <- (2013 - n.years + 1) : 2013
regions <- 1 : n.regions
temps.frame <- data.frame(regions = factor(rep(region.labels, each = n.years)),
                          times = rep(times, times = n.regions),
                          temps = temps.vect)
pdf(make.fn('anomaly.pdf'))
ggplot(data=temps.frame,
       aes(x = times, y = temps, group = regions, color = regions)) +
           geom_line() +
               labs(x="year", y="temp anomaly (celsius)", color="(lat,lon)")
dev.off()

## center data so model doesn't require an intercept (scale=F turns off scaling)
temps.mat.scaled <- scale(temps.mat, scale=F)
times.scaled <- scale(times, scale=F)

## run mcmc on 3 bugs linear regression models
## the goal is to infer the posterior over the slope of temps
## as a function of time
temps.data <- list(Y = n.years,
                   R = n.regions,
                   times = as.vector(times.scaled),
                   temps = as.matrix(temps.mat.scaled))

n.chains = 5
n.iter = 4000

## pooling -- a single slope for all regions
temps.pool.inits <- function() {
    list(b = rnorm(1),
         sigma.temps = runif(1))
}
temps.pool.parameters <- c("b", "sigma.temps")
temps.pool.fit <- jags(data = temps.data, inits = temps.pool.inits,
                       parameters.to.save = temps.pool.parameters,
                       model.file = "climate-pool.bug",
                       n.chains = n.chains, n.iter = n.iter)
print(temps.pool.fit)

## temps.pool.mcmc <- as.mcmc(temps.pool.fit)
## summary(temps.pool.mcmc)
## plot(temps.pool.mcmc)
## autocorr.plot(temps.pool.mcmc)

## no pooling -- a different slope for each region
temps.nopool.inits <- function() {
    list(b = rnorm(n.regions),
         sigma.temps = runif(1))
}
temps.nopool.parameters <- c("b", "sigma.temps")
temps.nopool.fit <- jags(data = temps.data, inits = temps.nopool.inits,
                         parameters.to.save = temps.nopool.parameters,
                         model.file = "climate-nopool.bug",
                         n.chains = n.chains, n.iter = n.iter)
print(temps.nopool.fit)

## hierarchical -- a different slope for each region, but with a shared prior over slopes
temps.hier.inits <- function() {
    list(b = rnorm(n.regions),
         sigma.temps = runif(1),
         mu.b = rnorm(1),
         sigma.b = runif(1))
}
temps.hier.parameters <- c("b", "sigma.temps", "mu.b", "sigma.b")
temps.hier.fit <- jags(data = temps.data, inits = temps.hier.inits,
                       parameters.to.save = temps.hier.parameters,
                       model.file = "climate-hier.bug",
                       n.chains = n.chains, n.iter = n.iter)
print(temps.hier.fit)
temps.hier.mcmc <- as.mcmc(temps.hier.fit)
temps.hier.means <- colMeans(as.matrix(temps.hier.mcmc))

## plot the 80% credible intervals for all parameters
pdf(make.fn('hier-posteriors.pdf'))
plot(autojags(temps.hier.fit))
dev.off()

## plot the expected slope for each region from the hier model
slope.means <- data.frame(matrix(ncol = 3, nrow = n.regions))
names(slope.means) <- list("lat", "lon", "b")
region <- 1
for(lat in lats) {
  for(lon in lons) {
    slope.means$lat[region] <- lat
    slope.means$lon[region] <- lon
    slope.means$b[region] <- temps.hier.means[sprintf("b[%d]",region)]
    region <- region + 1
  }
}

map <- get_map(location='World', zoom=2, maptype = "roadmap", color="bw")
pdf(make.fn('map-hier.pdf'))
ggmap(map) +
  geom_point(aes(x = lon, y = lat, color = b*100), size = 6, data = slope.means, alpha = 1.0) +
  scale_colour_gradient2(low="white", high="black") +
  labs(color="E[b]*100")
dev.off()




