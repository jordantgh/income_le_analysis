# Use the official R image as the base image
FROM r-base:latest

WORKDIR /app

COPY . /app

RUN apt-get update && apt-get install -y \
    gdal-bin \
    libgdal-dev \
    libssl-dev \
    libudunits2-dev \
    && rm -rf /var/lib/apt/lists/* \
    && Rscript --no-init-file -e 'source("requirements.r")' \
    && Rscript -e 'source("code/county/process_tables/pipelinescript.r")'

EXPOSE 3838

ENV NAME income_le_analysis

# Run the shiny app when the container launches
CMD ["R", "--slave", "-e", "shiny::runApp('code/shinyapp/shiny.r', port = 3838, host = '0.0.0.0')"]
