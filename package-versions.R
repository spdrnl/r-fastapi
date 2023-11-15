for (p in c('dplyr', 'parsnip', 'recipes', 'tibble', 'workflows')) {
  writeLines(sprintf("RUN R -e \\\"remotes::install_version('%s', '%s')\\\"", p, packageVersion(p)))
}
