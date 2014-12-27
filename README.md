bayesian-global-warming
=========================

This project is a Bayesian analysis of the rate of global warming in regions around
 the world, and was completed for a class on Bayesian Statistics. 
It contains three JAGS linear regression models, an R script that reads
<a href="http://data.giss.nasa.gov/gistemp/">GISTEMP</a> data, runs
 MCMC on the models, and plots graphs, and a paper describing the results.

Install
========

First, install R, JAGS, and Latex.

At the R prompt invoke
```
install.packages("ncdf", "R2jags", "ggplot2", "ggmap")
```

Download GISTEMP <a href="http://data.giss.nasa.gov/pub/gistemp/gistemp1200_ERSST.nc.gz">data</a> and put it in <project_root>/data/ subdirectory (which you need to create).

Run
=====

In <project_root>/code, run the R script by invoking
```
rScript climate.R
```
which will print the output of different models, and save figures
 to <project_root>/paper/figs/

To make the paper, go to paper/ and invoke
```
pdflatex document.tex
bibtex document
pdflatex document.tex
pdflatex document.tex
```