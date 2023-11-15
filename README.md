# r-fastapi

This project serves a Tidymodels R model through FastAPI using rpy2. There are several ways to serve Tidymodels instances:

-   Using plumber
-   Using vetiver
-   Using velvet

Although these methods all have their advantages, the R solutions seems rather closed or tied to Posit. The proposed setup is aimed at a setup that already has investments in FastAPI or Python, for example through connected middleware.

The setup is configured to create a container with 2 CPU and 4 worker threads. Each worker thread gets its own R instance. Because each FastAPI function is called standard with await, and R is not assumed to be async, threading should actually just work.

If all is well, middleware investments around monitoring in FastAPI, or any other Python setup, are reusable for Tidymodels. I think this is a step ahead.

## Considerations

The proposed setup works fine if data transformations are done in the context of a Tidymodels workflow. The more additional engineering is required outside of the workflow, the more code has to be duplicated between R and Python.

The assumption of the current setup is that in order to serve Tidymodels from Python, the required number of packages is low, and somewhat standard. Currently the following set of libraries are used within Python:

-   'dplyr'
-   'parsnip'
-   'recipes'
-   'tibble'
-   'workflows'

Additional libraries should be installed for models outside of standard lm, which is part of the R stats package.

The setup does not seem to deviate too much from a deployment with sklearn pipelines. Some smart modeling is in order in both cases to avert extra data transformation code.

And additional library called RhpcBLASctl is used to set the number of BLAS threads to 1. Otherwise concurrency could get messy.

## Modeling
A small three feature linear model with 3 features is generated with Tidymodels. The following steps are taken:

- The data is split in analysis and testing.
- Using v-fold cross-validation a small grid search is performed for a linear model.
- The best settings are used to fit the model on the complete analysis set.
- The workflow is slimmed down for prediction using the butcher library.

This setup represents a minimal viable workflow for model development.

## Performance

Performance for a small three variable linear model is around 100 requests per second per CPU. If this performance can persist over longer periods, it should cover quite some use cases.

Because a linear model is so simple, the performance should basically be see as the overhead of Python and R together for an API call. This overhead seems not overly burdensome. Note that both Python and R are in essence scripting languages.

For larger models one should assume that in quite some cases (lightGBM, XGBoost, ranger) the algorithms are implemented in high performance languages like C++ or Fortran.

## Prerequisits

This setup uses:

-   Make
-   podman
-   python (3.11)
-   poetry
-   R (4.3.1)
-   ab (Apache bench)

If your Python or R versions differ, try changing settings in pyproject.toml, then end of poetry.lock and renv.lock.

## How-to

There are several commands that can be executed with 'make':

-   make build-container
-   make run-container
-   make test-smoke
-   make test-stress

Additional commands can run the API using FastAPI locally without podman:

-   make run-api
-   make dev-api

The latter supports reloading of FastAPI.

Two additional command are more for development:

-   make generate-requirements
-   make package-versions

The first command generates a requirements.txt that is used to create the container. The second command generates an overview of R libraries that should be included in the container.

## Mixed Python and R setup
The project uses renv on the R side and poetry on the Python side. Both renv and poetry allow for the pinning down of both the libraries and their versions. This should provide for a stable setup.
For building the docker container a requirements file is generated using poetry. The R libraries with their version can be exported using 'make generate-requirements'. This generates a package_versions file, which can be pasted in the Containerfile.
## Improvements

The following improvements could be made:

-   Make environment variables work so that the number of FastAPI/uvicorn workers can be set during build or runtime.
-   Automatically change the package versions in the Containerfile. Likely best in the Makefile through a shell and sed solution.
-   Perform endurance tests.
