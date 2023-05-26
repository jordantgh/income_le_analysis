FROM r-base:4.3.0

# new user setup
ARG USER=ile_dev
ARG HOME=/home/${USER}

RUN apt update && apt install -y --no-install-recommends \
  # app dependencies:
  gdal-bin \
  libgdal-dev \
  libssl-dev \
  libudunits2-dev \
  # dev dependencies:
  sudo \
  adduser \
  openssh-client \
  zsh \
  command-not-found \
  git \
  libxml2-dev \
  libfontconfig1-dev \
  python3 \
  pipx \
  && pipx install radian \
  && pipx ensurepath \
  # dev user setup:
  && userdel -r docker \
  && adduser --disabled-password --gecos '' ${USER} \
  && adduser ${USER} sudo \
  && echo "${USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USER} \
  && chmod 0440 /etc/sudoers.d/${USER} \
  && chown -R ${USER}:${USER} ${HOME} \
  # clean up:
  && rm -rf /var/lib/apt/lists/* \
  && apt clean

EXPOSE 3832

USER ${USER}

# create a dir for user-specific R packages and set as default
RUN mkdir -p ${HOME}/R/x86_64-pc-linux-gnu-library
ENV R_LIBS_USER ${HOME}/R/x86_64-pc-linux-gnu-library

WORKDIR ${HOME}/bootstrapr
COPY ./requirements.r ${HOME}/bootstrapr
RUN Rscript -e 'source("requirements.r")'

WORKDIR ${HOME}/.zshconfig
COPY ./zsh/install.sh ${HOME}/.zshconfig/
COPY ./zsh/gitprompt.zsh ${HOME}/.zshconfig/
RUN sudo chmod +x ${HOME}/.zshconfig/install.sh && bash ${HOME}/.zshconfig/install.sh
COPY ./zsh/.zshrc ${HOME}/.zshrc