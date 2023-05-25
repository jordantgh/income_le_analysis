# Use the official R image as the base image
FROM r-base:latest

# new user setup
ARG USER=ile_dev
ARG HOME=/home/${USER}

RUN addgroup ${USER} \
    && adduser --disabled-password --gecos '' ${USER} \
    && adduser ${USER} sudo \
    && echo "${USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USER} \
    && chmod 0440 /etc/sudoers.d/${USER} \
    && mkdir -p ${HOME}/.zshconfig ${HOME}/bootstrapr

USER ${USER}
WORKDIR ${HOME}

RUN sudo apt update && sudo apt install -y \
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
  && sudo pipx install radian \
  && sudo pipx ensurepath \
  && sudo apt update \
  # clean up:
  && sudo rm -rf /var/lib/apt/lists/*

WORKDIR ${HOME}/.zshconfig
COPY ./zsh/install.sh ${HOME}/.zshconfig/
COPY ./zsh/gitprompt.zsh ${HOME}/.zshconfig/
RUN sudo chmod +x ${HOME}/.zshconfig/install.sh && bash ${HOME}/.zshconfig/install.sh
COPY ./zsh/.zshrc ${HOME}/.zshrc

WORKDIR ${HOME}/bootstrapr
COPY ./requirements.r ${HOME}/bootstrapr
RUN Rscript -e 'source("requirements.r")'

EXPOSE 3832
