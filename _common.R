set.seed(1112)
options(digits = 3)



knitr::opts_chunk$set(
  comment = "#>",
  collapse = TRUE,
  fig.width = 8,
  fig.asp = 0.618,  # 1 / phi
  fig.align = "center",
  message = F,
  warning = F
)

library(tidyverse)

options(dplyr.print_min = 6, dplyr.print_max = 6, datatable.print.nrows = 30)