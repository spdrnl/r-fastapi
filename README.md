# r-fastapi

This project serves a Tidymodels R model through FastAPI using rpy2.

There are several ways to serve Tidymodels instances:

-   Using plumber
-   Using vetiver
-   Using velvet

Although these methods have their advantages, the R solutions seem rather closed or tied to Posit. Going in this direction likely involves not only data scientists, but also data engineers to get involved with R. I do not think that is a viable option for most data teams.

Deployment wise Python provides lost of options, and many companies will have invested in Python and Python middleware. The proposed setup is aimed at such teams that already has investments in FastAPI or Python. It allows data scientists to work with R, broadening their reach, whilst at the same time capitalizing on current infrastructure. Note that this setup also translates to for example serverless functions.

The setup is configured to create a FastAPI container with 2 CPU and 4 worker threads. Each worker thread gets its own R instance. Because each FastAPI function is called standard with await, and R is not assumed to be async, threading should actually just work and scale.

If all is well, middleware investments around monitoring in FastAPI, or any other Python setup, are reusable for Tidymodels. I think this is a step ahead.

## Prerequisites

This setup uses:

-   Make
-   podman
-   python (3.11)
-   poetry
-   poetry-plugin-export
-   R (4.3.1)
-   ab (Apache bench)

If your Python or R versions differ, try changing settings in pyproject.toml, then at the end of poetry.lock and renv.lock.

Poetry and the poetry-plugin-export can be installed using pipx.

For those not used to Makefiles, I also wasn't. Until I found out that Makefiles are a great way to gather and automate all those command line snippets that make a project work. No need to remember these, store 'm in a Makefile!

## Instructions

After cloning renv and poetry should ensure that starting the project just works:

- Run renv::restore() after opening the project with R studio to install the R libraries.
- Run 'poetry install' in a terminal to create a Python environment. 

Use the script models.R to create and save a simple R model. The Python script model_test.py can be run from R Studio too, once the virtual env has been configured in the project settings. This script shows the basic workings of integrating R with Python using rpy2.

In the app directory a script is located that integrates this setup with FastAPI.

From here on a Makefile can used to execute different commands.

## How-to

There are several commands that can be executed with 'make':

-   make build-container
-   make run-container

Additional commands can run the API using FastAPI locally without podman:

-   make run-api
-   make dev-api

The latter supports reloading of FastAPI.

In both cases tests can be performed using the following commands:

-   make test-smoke
-   make test-stress

Two additional command are more for development:

-   make generate-requirements
-   make package-versions

The first command generates a requirements.txt that is used to create the container. The second command generates an overview of R libraries that should be included in the container.

## Modeling

A small three feature linear model with 3 features is generated with Tidymodels. The following steps are taken:

-   The data is split in analysis and testing.
-   Using v-fold cross-validation a small grid search is performed for a linear model.
-   The best settings are used to fit the model on the complete analysis set.
-   The workflow is slimmed down for prediction using the butcher library.

This setup represents a minimal viable workflow for model development.

## Performance

Performance for a small three variable linear model is around 100 requests per second per CPU. If this performance can persist over longer periods, it should cover quite some use cases.

Because a linear model is so simple, the performance should basically be seen as the overhead of Python and R together for an API call. This overhead seems not overly burdensome. Note that both Python and R are in essence scripting languages.

For larger models one should assume that in quite some cases (lightGBM, XGBoost, ranger) the algorithms are implemented in high performance languages like C++ or Fortran anyway, further blurring the Python and R differences.

## Considerations

The proposed setup works fine if data transformations are done in the context of a Tidymodels workflow and saved with the model. This works much in the same way as a sklearn Pipeline. The more additional engineering is required outside of the workflow, the more code has to be duplicated between R and Python. This goes for sklearn too, but then some code could be reused in the context of FastAPI.

All-in-all setup does not seem to deviate too much from a deployment with sklearn pipelines. Some smart modeling is in order in both cases to avert extra data transformation code.

The assumption of the current setup is that in order to serve Tidymodels from Python, the required number of packages is actually low, and somewhat standard. Currently the following set of libraries are used within Python:

-   'dplyr'
-   'parsnip'
-   'recipes'
-   'tibble'
-   'workflows'

Additional libraries should be installed for models outside of a standard linear model, which is part of the R stats package.

And additional library called RhpcBLASctl is used to set the number of BLAS threads to 1. Otherwise concurrency could get messy.

## Mixed Python and R setup

The project uses renv on the R side and poetry on the Python side. Both renv and poetry allow for the pinning down of both the libraries and their versions. This should provide for a stable setup. For building the docker container a requirements file is generated using poetry. The R libraries with their version can be exported using 'make generate-requirements'. This generates a package_versions file, which can be pasted in the Containerfile. (See improvements.)

## Improvements

The following improvements could be made:

-   Make environment variables work so that the number of FastAPI/uvicorn workers can be set during build or runtime. podman is failing me.
-   Automatically change the package versions in the Containerfile. Likely best in the Makefile through a shell and sed solution.
-   Perform endurance tests, refresh worker threads.
