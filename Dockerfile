ARG PRIVATE_REGISTRY

ARG UBUNTU_VER="24.04"
ARG BASE_VER_PFX=""
ARG BASE_IMG="ubuntu:${UBUNTU_VER}"

ARG SCRIPTS_REGISTRY="${PRIVATE_REGISTRY}"
ARG SCRIPTS_REPO="arkcase/base-container-scripts"
ARG SCRIPTS_VER="latest"
ARG SCRIPTS_VER_PFX="${BASE_VER_PFX}"
ARG SCRIPTS_IMG="${SCRIPTS_REGISTRY}/${SCRIPTS_REPO}:${SCRIPTS_VER_PFX}${SCRIPTS_VER}"

ARG MINIO_REGISTRY="${PRIVATE_REGISTRY}"
ARG MINIO_REPO="arkcase/minio"
ARG MINIO_VER="latest"
ARG MINIO_VER_PFX="${BASE_VER_PFX}"
ARG MINIO_IMG="${MINIO_REGISTRY}/${MINIO_REPO}:${MINIO_VER_PFX}${MINIO_VER}"

FROM "${SCRIPTS_IMG}" AS scripts

FROM "${MINIO_IMG}" AS minio

ARG BASE_IMG

FROM "${BASE_IMG}"

#
# Basic Parameters
#
ARG ARCH="amd64"
ARG OS="linux"
ARG VER="1.12.1"
ARG PKG="jenkins-build-base"
ARG APP_USER="jenkins"
ARG APP_UID="1000"
ARG APP_GROUP="${APP_USER}"
ARG APP_GID="${APP_UID}"

ARG DOCKER_KEYRING="https://download.docker.com/linux/ubuntu/gpg"
ARG DOCKER_PACKAGE_REPO="https://download.docker.com/linux/ubuntu"

ARG K8S_VER="1.35"
ARG K8S_KEYRING="https://pkgs.k8s.io/core:/stable:/v${K8S_VER}/deb/Release.key"
ARG K8S_PACKAGE_REPO="https://pkgs.k8s.io/core:/stable:/v${K8S_VER}/deb/"

ARG HELM_VER="3.18.5"
ARG HELM_SRC="https://get.helm.sh/helm-v${HELM_VER}-linux-amd64.tar.gz"

ARG GITHUB_KEYRING="https://cli.github.com/packages/githubcli-archive-keyring.gpg"
ARG GITHUB_REPO="https://cli.github.com/packages"

ARG GITLAB_REPO="https://raw.githubusercontent.com/upciti/wakemeops/main/assets/install_repository"

ARG YARN_KEYRING="https://dl.yarnpkg.com/debian/pubkey.gpg"
ARG YARN_REPO="https://dl.yarnpkg.com/debian/"

ARG AWS_SRC="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"

ARG GIT_LFS_VER="3.7.0"
ARG GIT_LFS_SRC="https://github.com/git-lfs/git-lfs/releases/download/v${GIT_LFS_VER}/git-lfs-linux-amd64-v${GIT_LFS_VER}.tar.gz"

ARG VCODE_VER="25.8.16.1"
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
ENV CACERTS="/etc/ssl/certs/java/cacerts"

ENV JVM_BASE="/usr/lib/jvm"
ENV JAVA_HOME="${JVM_BASE}/java"
ENV JRE_HOME="${JVM_BASE}/jre"
ENV VCODE_HOME="/opt/vcode-${VCODE_VER}"

#
# Everything but the multiversion tools, in a single layer: the base tools framework, the package repositories,
# the O/S updates and packages, the single-version tools (Helm, AWS, Git-LFS, the Veracode API wrapper, and
# Semgrep), and the build user
#
RUN --mount=type=bind,target=/src \
    --mount=type=bind,from=scripts,target=/scripts \
    --mount=type=bind,from=minio,source=/usr/local/bin,target=/minio \
    install -o root -g root -m 0755 -t /usr/local/bin /scripts/usr/local/bin/* /src/scripts/* /minio/minio && \
    install -o root -g root -m 0444 /scripts/.functions /.functions && \
    apt-get update && \
    apt-get -y install \
        curl \
        gpg \
        sudo \
      && \
    sed -e "s;\${APP_GROUP};${APP_GROUP};g" /src/01-set-java > /etc/sudoers.d/01-set-java && \
    chown root:root /etc/sudoers.d/01-set-java && \
    chmod 0440 /etc/sudoers.d/01-set-java && \
    curl -fsSL -o /etc/apt/trusted.gpg.d/github-archive.gpg "${GITHUB_KEYRING}" && \
    chmod go+r /etc/apt/trusted.gpg.d/github-archive.gpg && \
    echo "deb [arch=$(dpkg --print-architecture)] ${GITHUB_REPO} stable main" > /etc/apt/sources.list.d/github-cli.list && \
    curl -fsSL "${YARN_KEYRING}" | apt-key add - && \
    echo "deb ${YARN_REPO} stable main" > /etc/apt/sources.list.d/yarn.list && \
    curl -fsSL "${GITLAB_REPO}" | bash && \
    ( rm -f "${TRUSTED_GPG_DIR}/docker.gpg" &>/dev/null || true ) && \
    curl -fsSL "${DOCKER_KEYRING}" | gpg --dearmor -o "${TRUSTED_GPG_DIR}/docker.gpg" && \
    chmod a+r "${TRUSTED_GPG_DIR}/docker.gpg" && \
    DOCKER_DEB_DISTRO="$(. /etc/os-release && echo "${VERSION_CODENAME}")" && \
    echo "deb [arch=${ARCH}] ${DOCKER_PACKAGE_REPO} ${DOCKER_DEB_DISTRO} stable" > "${APT_SOURCES_DIR}/docker.list" && \
    curl -fsSL "${K8S_KEYRING}" | gpg --dearmor -o "${TRUSTED_GPG_DIR}/kubernetes.gpg" && \
    chmod a+r "${TRUSTED_GPG_DIR}/kubernetes.gpg" && \
    echo "deb ${K8S_PACKAGE_REPO} /" > "${APT_SOURCES_DIR}/kubernetes.list" && \
    CORETTO_KEYRING="${TRUSTED_GPG_DIR}/corretto-keyring.gpg" && \
    curl -fsSL "https://apt.corretto.aws/corretto.key" | gpg --dearmor -o "${CORETTO_KEYRING}" && \
    chmod a+r "${CORETTO_KEYRING}" && \
    echo "deb [signed-by=${CORETTO_KEYRING}] https://apt.corretto.aws stable main" | tee /etc/apt/sources.list.d/corretto.list && \
    apt-get update && \
    apt-get -y dist-upgrade -f && \
    apt-get -y install \
        autoconf \
        automake \
        bash-completion \
        bzip2 \
        ca-certificates \
        ca-certificates-java \
        dirmngr \
        default-libmysqlclient-dev \
        dos2unix \
        docker-buildx-plugin \
        docker-compose-plugin \
        docker-ce-cli \
        dpkg-dev \
        file \
        g++ \
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
        mutt \
        netbase \
        java-11-amazon-corretto-jdk \
        openjdk-17-jdk-headless \
        openjdk-21-jdk-headless \
        openjdk-25-jdk-headless \
        openssh-client \
        openssl \
        patch \
        poppler-utils \
        procps \
        python3-jinja2 \
        python3-pip \
        python3-venv \
        python3-yaml \
        rsync \
        sshpass \
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
    curl -fsSL "${HELM_SRC}" | tar -C /usr/local/bin --strip-components=1 --no-same-owner -xzvf - linux-amd64/helm && \
    chown root:root /usr/local/bin/helm && \
    chmod 0755 /usr/local/bin/helm && \
    kubectl completion bash > /usr/share/bash-completion/completions/kubectl && \
    helm completion bash > /usr/share/bash-completion/completions/helm && \
    find /usr/lib/jvm -type f -name cacerts | \
    while read file ; do \
        ln -v "${file}" "${file}.orig" && \
        rm -vf "${file}" && \
        ln -vs "${CACERTS}" "${file}" ; \
    done && \
    set-java 21 && \
    update-ca-certificates && \
    mkdir -p "/aws" && \
    curl -fsSL "${AWS_SRC}" -o "/aws/awscliv2.zip" && \
    ( cd "/aws" && unzip "awscliv2.zip" && ./aws/install ) && \
    rm -rf "/aws" && \
    echo "complete -C '/usr/local/bin/aws_completer' aws" > /etc/profile.d/02-aws.sh && \
    mkdir -p "/tmp/lfs" && \
    ( cd "/tmp/lfs" && curl -fsSL "${GIT_LFS_SRC}" | tar --strip-components=1 -xzvf - && bash install.sh ) && \
    rm -rf "/tmp/lfs" && \
    mvn-get "${VCODE_SRC}" "/tmp/veracode.zip" && \
    unzip -o -d "${VCODE_HOME}" "/tmp/veracode.zip" && \
    rm -rf "/tmp/veracode.zip" && \
    install-tool --target /tools /src/tools/semgrep && \
    groupadd -r build && \
    { getent group docker > /dev/null || groupadd -r docker ; } && \
    G="$(getent group "${APP_GID}" | cut -d: -f1)" && \
    if [ -n "${G}" ] ; then \
        groupmod -n "${APP_GROUP}" "${G}" ; \
    else \
        groupadd -g "${APP_UID}" "${APP_GROUP}" ; \
    fi && \
    if U="$(id -nu "${APP_UID}")" ; then \
        usermod -c "Jenkins Build User" -m -d "/home/${APP_USER}" -g "${APP_GID}" -G "build,docker" -s "/bin/bash" -a -l "${APP_USER}" "${U}" ; \
    else \
        useradd -c "Jenkins Build User" -m -d "/home/${APP_USER}" -g "${APP_GID}" -G "build,docker" -s "/bin/bash" -N -u "${APP_UID}" "${APP_USER}" ; \
    fi && \
    GITCONFIG="/home/${APP_USER}/.gitconfig" && \
    git config --file "${GITCONFIG}" credential.helper cache && \
    git config --file "${GITCONFIG}" --add safe.directory '*' && \
    chown "${APP_USER}:${APP_GROUP}" "${GITCONFIG}" && \
    chmod 0644 "${GITCONFIG}"

#
# The multiversion tools that only extract archives, each in its own layer. Their timestamps only depend on the
# archives (see install-tool --reproducible), so each layer is byte-identical from one build to the next (and is
# thus reused instead of shipped again) until that tool's versions change. Nothing else may go into these steps.
#
RUN --mount=type=bind,source=tools,target=/src/tools \
    install-tool --reproducible --target /tools /src/tools/mvn
RUN --mount=type=bind,source=tools,target=/src/tools \
    install-tool --reproducible --target /tools /src/tools/go
RUN --mount=type=bind,source=tools,target=/src/tools \
    install-tool --reproducible --target /tools /src/tools/node

#
# Now do the configurations for the actual user
#
USER "${APP_USER}"

#
# Final parameters
#
VOLUME      [ "/home/${APP_USER}" ]

WORKDIR     "/home/${APP_USER}"
ENTRYPOINT  [ "/usr/bin/bash", "-i" ]
