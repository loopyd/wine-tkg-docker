# A base image with build tools and user setup for building applications.  The following
# environment variables are used to configure the image:
#
# - `APP_USER`: The name of the user to create.  Defaults to `appuser`.
# - `LANG`: The locale to use.  Defaults to `en_US.UTF-8`.
# - `TZ`: The timezone to use.  Defaults to `America/Los_Angeles`.
# - `PYENV_ROOT`: The location of the pyenv installation.  Defaults to `/usr/local/pyenv`.
# - `NVM_DIR`: The location of the nvm installation.  Defaults to `/usr/local/nvm`.
# - `NODE_VERSION`: The version of node to install.  Defaults to `lts/gallium`.
# - `GOSU_VERSION`: The version of gosu to install.  Defaults to `1.16`.
# - `CARGO_DIR`: The location of the cargo installation.  Defaults to `/usr/local/rust/cargo`.
# - `RUSTUP_DIR`: The location of the rustup installation.  Defaults to `/usr/local/rust/multirust`.
# - `APP_DIR`: The location of the application.  Defaults to `/app`.
#
FROM ubuntu:jammy

ARG APP_USER
ARG APP_USER_HOME
ARG LANG
ARG TZ
ARG PYENV_ROOT
ARG NVM_DIR
ARG NODE_VERSION
ARG GOSU_VERSION
ARG PYTHON_VERSION
ARG CARGO_DIR
ARG RUSTUP_DIR
ARG APP_DIR

ENV APP_USER ${APP_USER:-appuser}
ENV APP_USER_HOME ${APP_USER_HOME:-/home/${APP_USER}}
ENV APP_DIR ${APP_DIR:-/app}
ENV LANG ${LANG:-"en_US.UTF-8"}
ENV TZ ${TZ:-America/Los_Angeles}
ENV PYENV_ROOT ${PYENV_ROOT:-/usr/local/pyenv}
ENV NVM_DIR ${NVM_DIR:-/usr/local/nvm}
ENV NODE_VERSION ${NODE_VERSION:-lts/gallium}
ENV GOSU_VERSION ${GOSU_VERSION:-1.16}
ENV PYTHON_VERSION ${PYTHON_VERSION:-3.7.17}
ENV CARGO_DIR ${CARGO_DIR:-/usr/local/rust/cargo}
ENV RUSTUP_DIR ${RUSTUP_DIR:-/usr/local/rust/multirust}
ENV DEBIAN_FRONTEND noninteractive

# Generate locale
RUN set -eux; \
	if [ -f /etc/dpkg/dpkg.cfg.d/docker ]; then \
		grep -q '/usr/share/locale' /etc/dpkg/dpkg.cfg.d/docker; \
		sed -ri '/\/usr\/share\/locale/d' /etc/dpkg/dpkg.cfg.d/docker; \
		! grep -q '/usr/share/locale' /etc/dpkg/dpkg.cfg.d/docker; \
	fi ;\
	apt-get update ;\
    apt-get install -qqy --no-install-recommends \
        locales ;\
    rm -rf /var/lib/apt/lists/* ;\
    echo "$LANG "$(echo $LANG | awk -F'.' '{print $2}') > /etc/locale.gen; \
	locale-gen; \
    locale -a

# Set timezone
RUN set -eux; \
    apt-get -qqy update; \
    apt-get install -qqy --no-install-recommends \
        tzdata; \
    rm -rf /var/lib/apt/lists/*; \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime; \
    echo $TZ > /etc/timezone; \
    dpkg-reconfigure -f noninteractive tzdata

# Install gosu
RUN set -eux; \
	savedAptMark="$(apt-mark showmanual)"; \
	apt-get -qqy update; \
	apt-get install -qqy --no-install-recommends \
        ca-certificates \
        wget \
        gnupg \
        less; \
    apt-get -qqy autoremove; \
    apt-get -qqy clean autoclean; \
    rm -rf /var/lib/apt/lists/{apt,dpkg,cache,log} /tmp/* /var/tmp/* ;\
	dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
	wget -qO /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
	wget -qO /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --quiet --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
	gpg --quiet --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
	apt-mark auto '.*' > /dev/null; \
	[ -z "$savedAptMark" ] || apt-mark manual $savedAptMark > /dev/null; \
	chmod +x /usr/local/bin/gosu; \
	gosu nobody true

# Install build dependencies
RUN apt-get -qqy update && \
    apt-get install -qqy --no-install-recommends \
        autoconf \
        automake \
        bison \
        build-essential \
        bzip2 \
        ca-certificates \
        clang \
        cmake \
        curl \
        flex \
        gcc \
        gettext \
        git \
        g++ \
        gnupg \
        gfortran \
        gzip \
        libblas-dev \
        libbz2-dev \
        libffi-dev \
        libicu-dev \
        libkrb5-dev \
        liblapack-dev \
        libldap2-dev \
        liblz4-dev \
        liblzma-dev \
        libmecab-dev \
        libmecab2 \
        libncurses5-dev \
        libncursesw5-dev \
        libnss-wrapper \
        libpam0g-dev \
        libperl-dev \
        libpng-dev \
        libpq-dev \
        libpython3-dev \
        libreadline-dev \
        libselinux1-dev \
        libsqlite3-dev \
        libssl-dev \
        libsystemd-dev \
        libtcl-perl \
        libtool \
        libxml2-dev \
        libxmlsec1-dev \
        libzstd-dev \
        llvm \
        make \
        meson \
        nasm \
        ninja-build \
        openssl \
        pkg-config \
        software-properties-common \
        sudo \
        swig \
        tcl-dev \
        tcllib \
        tar \
        tk-dev \
        uuid-dev \
        wget \
        xz-utils \
        zlib1g-dev; \
    dpkg --add-architecture i386; \
    apt -qqy update; \
    apt-get -qqy autoremove; \
    apt-get -qqy clean autoclean; \
    rm -rf /var/lib/apt/lists/{apt,dpkg,cache,log} /tmp/* /var/tmp/*

# Setup user
RUN adduser --disabled-password --gecos '' --shell /bin/bash --home ${APP_USER_HOME} ${APP_USER} ;\
    usermod -aG sudo ${APP_USER}; \
    echo "${APP_USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Setup pyenv
USER root
RUN mkdir -p $PYENV_ROOT; \
    groupadd python; \
    chown -R root:python $PYENV_ROOT; \
    chmod -R 1775 $PYENV_ROOT; \
    usermod -aG python ${APP_USER}
USER ${APP_USER}
WORKDIR ${APP_USER_HOME}
RUN git clone --depth=1 https://github.com/pyenv/pyenv.git /usr/local/pyenv
ENV PATH ${PYENV_ROOT}/shims:${PYENV_ROOT}/bin:$PATH
RUN pyenv install ${PYTHON_VERSION}; \
    pyenv global ${PYTHON_VERSION}; \
    pyenv rehash; \
    pip install --upgrade pip; \
    pip install --upgrade setuptools wheel

# Setup node
USER root
RUN mkdir -p $NVM_DIR; \
    groupadd node; \
    chown -R root:node $NVM_DIR; \
    chmod -R 1775 $NVM_DIR; \
    usermod -aG node ${APP_USER}
USER ${APP_USER}
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.39.7/install.sh | bash; \
    /bin/bash -c "source $NVM_DIR/nvm.sh && nvm install $NODE_VERSION && nvm use --delete-prefix $NODE_VERSION"
ENV NODE_PATH $NVM_DIR/versions/node/$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/versions/node/$NODE_VERSION/bin:$HOME/.local/bin:$PATH

# Setup rust
USER root
RUN mkdir -p $CARGO_DIR \
             $RUSTUP_DIR ;\
    groupadd rust; \
    chown -R root:rust $CARGO_DIR \
                       $RUSTUP_DIR; \
    chmod -R 1775 $CARGO_DIR \
                  $RUSTUP_DIR; \
    usermod -aG rust ${APP_USER}

VOLUME ["${APP_DIR}"]
RUN mkdir -p ${APP_DIR}; \
    chown -R ${APP_USER}:${APP_USER} ${APP_DIR}; \
    chmod -R 1755 ${APP_DIR}

COPY --chmod=4777 docker-entrypoint.sh /usr/local/bin/
RUN ln -sT /usr/local/bin/docker-entrypoint.sh /docker-entrypoint.sh 

USER ${APP_USER}
ENV CARGO_HOME $CARGO_DIR
ENV RUSTUP_HOME $RUSTUP_DIR
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH $CARGO_DIR/bin:$PATH

WORKDIR ${APP_DIR}
ENTRYPOINT ["/docker-entrypoint.sh"]
