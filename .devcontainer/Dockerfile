# Use the official R image as the base image
FROM r-base:latest

# new user setup
ARG USER=ile_dev
ARG HOME=/home/${USER}

RUN apt update && apt install -y sudo adduser \
    && adduser --disabled-password --gecos '' ${USER} \
    && adduser ${USER} sudo \
    && echo "${USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USER} \
    && chmod 0440 /etc/sudoers.d/${USER} \
    && chown -R ${USER}:${USER} ${HOME}

# Switch to new user
USER ${USER}

# Create a directory for user-specific R packages and set it as default
RUN mkdir -p ${HOME}/R/x86_64-pc-linux-gnu-library
ENV R_LIBS_USER ${HOME}/R/x86_64-pc-linux-gnu-library

# Switch back to root for installations
USER root

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


WORKDIR ${HOME}/bootstrapr
COPY ./requirements.r ${HOME}/bootstrapr
RUN Rscript -e 'source("requirements.r")'

EXPOSE 3832

RUN userdel -r docker
RUN apt update && apt install openssh-client -y

USER ${USER}
WORKDIR ${HOME}/.zshconfig
COPY ./zsh/install.sh ${HOME}/.zshconfig/
COPY ./zsh/gitprompt.zsh ${HOME}/.zshconfig/
RUN sudo chmod +x ${HOME}/.zshconfig/install.sh && bash ${HOME}/.zshconfig/install.sh
COPY ./zsh/.zshrc ${HOME}/.zshrc