# Start from rocker r-base image
FROM r-base:4.3.1 as r-fastapi-base

## Install R package dependencies
# Bootstrap R environment
RUN apt-get update \
    && apt-get install -y --no-install-recommends libcurl4-openssl-dev \
    && R -e "install.packages('remotes', repos = c(CRAN = 'https://cloud.r-project.org'))" \
    && rm -rf /var/lib/apt/lists/*

# Install R packages
RUN R -s -e "remotes::install_version('dplyr', '1.1.3')" \
    && R -s -e "remotes::install_version('parsnip', '1.1.1')" \
    && R -s -e "remotes::install_version('recipes', '1.0.8')" \
    && R -s -e "remotes::install_version('tibble', '3.2.1')" \
    && R -s -e "remotes::install_version('workflows', '1.1.3')" \
    && R -s -e "remotes::install_version('RhpcBLASctl')"

## Install python
# Install code
WORKDIR /code
COPY ./app /code/app
COPY model.rds /code/model.rds
COPY ./requirements.txt /code/requirements.txt

# Install python interpreter, venv and libraries
RUN apt-get update \
  && apt-get -y --no-install-recommends install python3 python3-dev python3-venv \
  && python3 -m venv /opt/venv \
  && rm -rf /var/lib/apt/lists/* \
  && /opt/venv/bin/pip install --no-cache-dir --upgrade -r /code/requirements.txt

## Configure container startup command
FROM r-fastapi-base
ENV PATH="/opt/venv/bin:$PATH"
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "80", "--workers", "4"]
