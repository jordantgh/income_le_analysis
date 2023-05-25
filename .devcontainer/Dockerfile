# Use the official R image as the base image
FROM r-base:latest

RUN apt update && apt install -y \
  # app dependencies:
  gdal-bin \
  libgdal-dev \
  libssl-dev \
  libudunits2-dev \
  # dev dependencies:
  zsh \
  command-not-found \
  git \
  libxml2-dev \
  libfontconfig1-dev \
  python3 \
  pipx \
  && pipx install radian \
  && pipx ensurepath \
  && apt update \
  # clean up:
  && rm -rf /var/lib/apt/lists/*

WORKDIR /root/.zshconfig
COPY ./zsh/install.sh /root/.zshconfig/
COPY ./zsh/gitprompt.zsh /root/.zshconfig/
RUN chmod +x /root/.zshconfig/install.sh && bash /root/.zshconfig/install.sh
COPY ./zsh/.zshrc /root/.zshrc

WORKDIR /bootstrapr
COPY ./requirements.r /bootstrapr
RUN Rscript -e 'source("requirements.r")'

EXPOSE 3832