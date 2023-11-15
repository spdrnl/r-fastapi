import pandas as pd
import rpy2.robjects as ro
from rpy2.robjects.packages import importr
from rpy2.robjects import pandas2ri
import json

base = importr('base')
stats = importr('stats')
dplyr = importr('dplyr')
parsnip = importr('parsnip')
recipes = importr('recipes')
tibble = importr('tibble')
workflows = importr('workflows')

model = base.readRDS("model.rds")
data = json.load(open('data.json'))
pd_df = pd.DataFrame([data])

with (ro.default_converter + pandas2ri.converter).context():
  r_from_pd_df = ro.conversion.get_conversion().py2rpy(pd_df)
  r_df = stats.predict(model, r_from_pd_df)
  pandas_rf = ro.conversion.rpy2py(r_df)
  print(pandas_rf.to_dict())




