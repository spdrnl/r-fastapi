from fastapi import FastAPI
from typing import List
from pydantic import BaseModel

import pandas as pd
import rpy2.robjects as ro
from rpy2.robjects.packages import importr
from rpy2.robjects import pandas2ri

# Import R packages
base = importr('base')
stats = importr('stats')
dplyr = importr('dplyr')
parsnip = importr('parsnip')
recipes = importr('recipes')
tibble = importr('tibble')
workflows = importr('workflows')

# Import package to control BLAS threads
RhpcBLASctl = importr('RhpcBLASctl')
RhpcBLASctl.blas_set_num_threads(1)

# Init the R model
model = base.readRDS("model.rds")

# Define input format
class Item(BaseModel):
    cyl: int
    disp: float
    wt: float

# Predict help function
def predict_items(items: List[Item]):
  pd_df = pd.DataFrame([item.dict() for item in items])
  with (ro.default_converter + pandas2ri.converter).context():
    r_from_pd_df = ro.conversion.get_conversion().py2rpy(pd_df)
    r_df = stats.predict(model, r_from_pd_df)
    pandas_rf = ro.conversion.rpy2py(r_df)
    return pandas_rf.to_dict('records')
  
# Init the server
app = FastAPI()


# Define functions
@app.get("/")
def read_root():
    return {"Hello": "World"}


@app.post("/predict/")
async def create_item(item: Item):
  return predict_items([item])[0]

  
@app.post("/predict_list/")
async def create_items(items: List[Item]):
  return predict_items(items)
    






