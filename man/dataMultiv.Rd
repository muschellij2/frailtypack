% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/dataHelp.R
\docType{data}
\name{dataMultiv}
\alias{dataMultiv}
\title{Simulated data for two types of recurrent events and a terminal event}
\format{This data frame contains the following columns: \describe{
\item{PATIENT}{identification of patient} \item{obs}{number of observation
for a patient} \item{TIME0}{start of interval} \item{TIME1}{end of interval
(death or censoring time)} \item{INDICREC}{recurrent of type 1 status (0:no,
1:yes)} \item{INDICMETA}{recurrent of type 2 status (0:no, 1:yes)}
\item{INDICDEATH}{censoring status (0:alive, 1:death)} \item{v1}{dichotomous
covariate (0,1)} \item{v2}{dichotomous covariate (0,1)}
\item{v3}{dichotomous covariate (0,1)} \item{TIMEGAP}{time to event} }}
\usage{
data(dataMultiv)
}
\description{
This contains a simulated sample of of 800 subjects and 1652 observations.
This dataset can be used to illustrate how to fit a joint multivariate
frailty model. Two gaussian correlated random effects were generated with
mean 0, variances 0.5 and a correlation coefficient equals to 0.5. The
coefficients \eqn{\alpha_1} and \eqn{\alpha_2} were fixed to 1. The three
baseline hazard functions followed a Weibull distribution and right
censoring was fixed at 5.
}
\keyword{datasets}
