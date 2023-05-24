# Use the official R image as the base image
FROM r-base:latest

WORKDIR /bootstrap

RUN apt update && apt install -y \
  # app dependencies:
  gdal-bin \
  libgdal-dev \
  libssl-dev \
  libudunits2-dev \
  # dev dependencies:
  git \
  libxml2-dev \
  libfontconfig1-dev \
  python3 \
  pipx \
  && pipx install radian \
  && pipx ensurepath \
  # clean up:
  && rm -rf /var/lib/apt/lists/*

COPY ./requirements.r /bootstrap
RUN Rscript -e 'source("requirements.r")'

EXPOSE 3832