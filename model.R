
### load packages
library(tidymodels)
library(tidyverse)
library(butcher)

############ Regression Example ############
### get data
df <- mtcars
head(df)

### split the data
split = initial_validation_split(df)
df_train = training(split)
df_test = testing(split)

### cross validation folds
df_cv <- vfold_cv(df_train, v = 10)
df_cv

### specify linear model
lm_spec <- linear_reg() %>%
  set_engine("lm") %>%
  set_mode("regression")

### recipe
mpg_rec <- recipe(mpg ~ cyl + disp + wt, data = df)
mpg_rec

### workflow
mpg_wf <- workflow() %>%
  add_recipe(mpg_rec) %>%
  add_model(lm_spec)

### set a control function to save the predictions from the model fit to the CV-folds
ctrl <- control_resamples(save_pred = TRUE)

### fit model
mpg_lm <- mpg_wf %>%
  fit_resamples(
    resamples = df_cv,
    control = ctrl
  )

mpg_lm

### view model metrics
collect_metrics(mpg_lm)

### get predictions
mpg_lm %>%
  unnest(cols = .predictions) %>%
  select(.pred, mpg)

## Fit the final model & extract the workflow
mpg_final <- mpg_wf %>%
  finalize_workflow(select_best(mpg_lm, metric = 'rmse')) %>%
  last_fit(split) %>%
  extract_workflow()

# We can save the model in a file using saveRDS
# Using butcher to save space
saveRDS(butcher(mpg_final), "model.rds")

# Now we can read the model from file saving all the time used in training the model
model_from_file <- readRDS("model.rds")

test = tibble(cyl = 6, disp = 160, wt = 2.620)
predict(model_from_file, test)
