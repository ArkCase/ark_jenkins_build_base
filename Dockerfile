FROM ubuntu:latest

#
# Basic Parameters
#
ARG ARCH="amd64"
ARG OS="linux"
ARG VER="1.0.3"
ARG PKG="jenkins-build-base"
ARG APP_USER="jenkins"
ARG APP_UID="1000"
ARG APP_GROUP="builder"
ARG APP_GID="1000"

ARG DOCKER_KEYRING="https://download.docker.com/linux/ubuntu/gpg"
ARG DOCKER_DEB_DISTRO="jammy"
ARG DOCKER_PACKAGE_REPO="https://download.docker.com/linux/ubuntu"

ARG K8S_VER="1.28"
ARG K8S_KEYRING="https://pkgs.k8s.io/core:/stable:/v${K8S_VER}/deb/Release.key"
ARG K8S_PACKAGE_REPO="https://pkgs.k8s.io/core:/stable:/v${K8S_VER}/deb/"

ARG HELM_VER="3.12.3"
ARG HELM_SRC="https://get.helm.sh/helm-v${HELM_VER}-linux-amd64.tar.gz"

ARG GITHUB_KEYRING="https://cli.github.com/packages/githubcli-archive-keyring.gpg"
ARG GITHUB_REPO="https://cli.github.com/packages"

ARG GITLAB_REPO="https://raw.githubusercontent.com/upciti/wakemeops/main/assets/install_repository"

ARG YARN_KEYRING="https://dl.yarnpkg.com/debian/pubkey.gpg"
ARG YARN_REPO="https://dl.yarnpkg.com/debian/"

ARG AWS_SRC="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"

ARG AWX_SRC="https://releases.ansible.com/ansible-tower/cli/ansible-tower-cli-latest.tar.gz"

ARG GIT_LFS_VER="3.5.1"
ARG GIT_LFS_SRC="https://github.com/git-lfs/git-lfs/releases/download/v${GIT_LFS_VER}/git-lfs-linux-amd64-v${GIT_LFS_VER}.tar.gz"

ARG VCODE_VER="23.8.12.0"
ARG VCODE_SRC="com.veracode.vosp.api.wrappers:vosp-api-wrappers-java:${VCODE_VER}:zip:dist"

#
# Some important labels
#
LABEL ORG="Armedia LLC"
LABEL MAINTAINER="Armedia Devops Team <devops@armedia.com>"
LABEL APP="Jenkins Build Base Image"
LABEL VERSION="${VER}"
LABEL IMAGE_SOURCE="https://github.com/ArkCase/ark_jenkins_build_base"

#
# Base environment variables
#
ENV APP_USER="${APP_USER}"
ENV APP_UID="${APP_UID}"
ENV APP_GID="${APP_GID}"
ENV APP_VER="${VER}"
ENV TRUSTED_GPG_DIR="/etc/apt/trusted.gpg.d"
ENV APT_SOURCES_DIR="/etc/apt/sources.list.d"

#
# Prep to make GitLab CLI and GitHub CLI available
#
RUN apt-get update && \
    apt-get install -y \
        curl \
        gpg \
      && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    curl -fsSL -o /etc/apt/trusted.gpg.d/github-archive.gpg "${GITHUB_KEYRING}" && \
    chmod go+r /etc/apt/trusted.gpg.d/github-archive.gpg && \
    echo "deb [arch=$(dpkg --print-architecture)] ${GITHUB_REPO} stable main" > /etc/apt/sources.list.d/github-cli.list && \
    curl -fsSL "${YARN_KEYRING}" | apt-key add - && \
    echo "deb ${YARN_REPO} stable main" > /etc/apt/sources.list.d/yarn.list && \
    curl -fsSL "${GITLAB_REPO}" | bash && \
    ( rm -f "${TRUSTED_GPG_DIR}/docker.gpg" &>/dev/null || true ) && \
    curl -fsSL "${DOCKER_KEYRING}" | gpg --dearmor -o "${TRUSTED_GPG_DIR}/docker.gpg" && \
    chmod a+r "${TRUSTED_GPG_DIR}/docker.gpg" && \
    echo "deb [arch=${ARCH}] ${DOCKER_PACKAGE_REPO} ${DOCKER_DEB_DISTRO} stable" > "${APT_SOURCES_DIR}/docker.list" && \
    curl -fsSL "${K8S_KEYRING}" | gpg --dearmor -o "${TRUSTED_GPG_DIR}/kubernetes.gpg" && \
    chmod a+r "${TRUSTED_GPG_DIR}/kubernetes.gpg" && \
    echo "deb ${K8S_PACKAGE_REPO} /" > "${APT_SOURCES_DIR}/kubernetes.list"


#
# O/S updates, and base tools
#
RUN apt-get update && \
    apt-get -y dist-upgrade -f && \
    apt-get install -y \
        autoconf \
        automake \
        bzip2 \
        bzr \
        ca-certificates \
        ca-certificates-java \
        containerd.io \
        dirmngr \
        default-libmysqlclient-dev \
        dos2unix \
        docker-buildx-plugin \
        docker-compose-plugin \
        docker-ce \
        docker-ce-cli \
        dpkg-dev \
        file \
        g++ \
        gcc \
        gcc \
        gettext-base \
        gh \
        git \
        git-flow \
        glab \
        gnupg \
        imagemagick \
        jq \
        kubectl \
        libbz2-dev \
        libc6-dev \
        libcurl4-openssl-dev \
        libdb-dev \
        libevent-dev \
        libffi-dev \
        libgdbm-dev \
        libgeoip-dev \
        libglib2.0-dev \
        libgmp-dev \
        libjpeg-dev \
        libkrb5-dev \
        liblzma-dev \
        libmagickcore-dev \
        libmagickwand-dev \
        libncurses5-dev \
        libncursesw5-dev \
        libpng-dev \
        libpq-dev \
        libreadline-dev \
        libsqlite3-dev \
        libssl-dev \
        libtool \
        libwebp-dev \
        libxml2-dev \
        libxml2-utils \
        libxslt-dev \
        libyaml-dev \
        make \
        mercurial \
        mutt \
        netbase \
        openssh-client \
        openssl \
        patch \
        procps \
        python3-pip \
        rsync \
        sshpass \
        subversion \
        unzip \
        vim \
        wget \
        xmlstarlet \
        xz-utils \
        yarn \
        zip \
        zlib1g-dev \
      && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    curl -fsSL "${HELM_SRC}" | tar -C /usr/local/bin --strip-components=1 -xzvf - linux-amd64/helm

#
# Install all the base tools framework
#
COPY --chown=root:root scripts/ /usr/local/bin

#
# Add AWS (no need to add it as a separate tool b/c we only ever need 1 version)
#
RUN mkdir -p "/aws" && \
    curl -fsSL "${AWS_SRC}" -o "/aws/awscliv2.zip" && \
    cd "/aws" && \
    unzip "awscliv2.zip" && \
    ./aws/install && \
    cd / && \
    rm -rf "/aws"

#
# Add AWX (no need to add it as a separate tool b/c we only ever need 1 version)
#
RUN pip3 install "${AWX_SRC}"

#
# Add Git-LFS (no need to add it as a separate tool b/c we only ever need 1 version)
#
RUN mkdir -p "/tmp/lfs" && \
    cd "/tmp/lfs" && \
    curl -fsSL "${GIT_LFS_SRC}" | tar --strip-components=1 -xzvf - && \
    bash install.sh && \
    cd "/tmp" && \
    rm -rf "lfs"

#
# Install the Veracode API Wrapper (no need to add it as a separate tool b/c we only ever need 1 version)
#
ENV VCODE_HOME="/opt/vcode-${VCODE_VER}"
RUN mvn-get "${VCODE_SRC}" "/tmp/veracode.zip" && \
    unzip -o -d "${VCODE_HOME}" "/tmp/veracode.zip" && \
    rm -rf "/tmp/veracode.zip"

#
# Execute the multiversion tool installations
#
COPY --chown=root:root scripts/install-tool /usr/local/bin
ADD --chown=root:root tools /tools
RUN install-tool /tools/*

#
# Add the default initializers & configurators
#
COPY --chown=root:root init.d /init.d
COPY --chown=root:root conf.d /conf.d

#
# Create the user and their home
#
RUN groupadd --system "build"
RUN groupadd --gid "${APP_GID}" "${APP_GROUP}"
RUN useradd --uid "${APP_UID}" --gid "${APP_GID}" --groups "build,docker" -m --home-dir "/home/${APP_USER}" "${APP_USER}"

#
# Now do the configurations for the actual user
#
USER "${APP_USER}"

#
# Configure Git for the build user
#
RUN /usr/bin/git config --global credential.helper cache && \
    /usr/bin/git config --global --add safe.directory '*'

#
# Final parameters
#
VOLUME      [ "/init.d" ]
VOLUME      [ "/cache" ]
VOLUME      [ "/home/${APP_USER}" ]

WORKDIR     "/home/${APP_USER}"
ENTRYPOINT  [ "/usr/bin/bash", "-i" ]
