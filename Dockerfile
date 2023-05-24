# Use the official R image as the base image
FROM r-base:latest

WORKDIR /app

COPY . /app

RUN apt-get update && apt-get install -y \
  gdal-bin \
  libgdal-dev \
  libssl-dev \
  libudunits2-dev \
  && rm -rf /var/lib/apt/lists/*

RUN Rscript --no-init-file -e 'source("requirements.r")'

RUN Rscript -e 'source("code/init.r")'

RUN Rscript -e 'source("code/process_tables/pipelinescript.r")'

EXPOSE 3832

# Run the shiny app when the container launches
CMD ["R", "--slave", "-e", "shiny::runApp('code/shinyapp/app.r', port = 3832, host = '0.0.0.0')"]
