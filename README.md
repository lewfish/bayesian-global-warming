bayesian-global-warming
=========================

This project is a Bayesian analysis of the rate of global warming in regions around
 the world, and was completed for a class on Bayesian Statistics. 
It contains 1) three JAGS linear regression models, 2) an R script that reads
<a href="http://data.giss.nasa.gov/gistemp/">GISTEMP</a> data, runs
 MCMC on the models, and plots graphs, and 3) a paper describing the results.

Install
========

Install R, JAGS, and Latex.

At the R prompt invoke
```
install.packages("ncdf", "R2jags", "ggplot2", "ggmap")
```

Download GISTEMP <a href="http://data.giss.nasa.gov/pub/gistemp/gistemp1200_ERSST.nc.gz">data</a> and put it in data/ subdirectory (which you need to create).

Run
=====

In code/, run the R script by invoking
```
Rscript climate.R
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