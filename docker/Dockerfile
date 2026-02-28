#=====================================================
# BASE STAGE
#=====================================================
FROM ubuntu:22.04 AS base

ARG DEBIAN_FRONTEND=nointeractive
ARG CONTAINER_USER=dev
ARG USER_UID=1000
ARG USER_GID=$USER_UID

ARG TARGETPLATFORM=linux/amd64
ARG TARGETARCH=amd64

######################################################
# Common Dependencies
######################################################

# Install sudo first before modifying sudoers
RUN apt-get update && apt-get install -y sudo && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# depending of the base image, the user 1000 may already exist
RUN if getent passwd 1000 > /dev/null 2>&1; then \
    existing_user=$(getent passwd 1000 | cut -d: -f1) && \
    userdel -r "$existing_user"; \
    fi && \
    groupadd --gid $USER_GID $CONTAINER_USER && \
    adduser --uid $USER_UID --gid $USER_GID --disabled-password --gecos "" ${CONTAINER_USER} && \
    usermod -a -G root $CONTAINER_USER && \
    usermod -a -G dialout $CONTAINER_USER && \
    usermod -a -G plugdev $CONTAINER_USER
RUN echo "" >> /etc/sudoers && echo "$CONTAINER_USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Install common dependencies
RUN apt-get update && apt-get install -y \
    apt-utils \
    bison \
    build-essential \
    ca-certificates \
    ccache \
    check \
    curl \
    dfu-util \
    flex \
    gcc-arm-none-eabi \
    gdb-multiarch \
    git \
    git-lfs \
    gperf \
    lcov \
    libffi-dev \
    libncurses5 \
    libncurses-dev \
    libssl-dev \
    libusb-1.0-0-dev \
    nano \
    ninja-build \
    python3 \
    python3-pip \
    udev \
    unzip \
    wget \
    openjdk-21-jdk \
    openjdk-21-jre \
    xvfb \
    xz-utils \
    zip \
    ncdu \
    iputils-ping \
    htop && \
    apt-get autoremove -y && rm -rf /var/lib/apt/lists/*

RUN if [ "$TARGETARCH" = "amd64" ]; then \
    JLINK_ARCH="x86_64"; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
    JLINK_ARCH="arm64"; \
    else \
    echo "Unsupported architecture: $TARGETARCH"; \
    exit 1; \
    fi && \
    wget --post-data "accept_license_agreement=accepted" https://www.segger.com/downloads/jlink/JLink_Linux_$JLINK_ARCH.deb -O /opt/jlink.deb


######################################################
# CubeMX and STM32CubeProgrammer Installation
######################################################
ENV CUBE_PATH="/home/${CONTAINER_USER}/STM32CubeMX"
COPY st.tar.gz /tmp/st.tar.gz
RUN tar -xzf /tmp/st.tar.gz -C /opt && \
    rm /tmp/st.tar.gz && \
    chown -R ${CONTAINER_USER}:${CONTAINER_USER} /opt/st/Repository

# Install CubeMx
RUN wget -nv https://sw-center.st.com/packs/resource/library/stm32cube_mx_v6160-lin.zip -O /tmp/cubemx.zip && \
    unzip -q /tmp/cubemx.zip -d /tmp/mx && \
    rm /tmp/cubemx.zip && \
    mv /tmp/mx/MX ${CUBE_PATH} && \
    rm -rf /tmp/mx && \
    mv ${CUBE_PATH}/STM32CubeMX ${CUBE_PATH}/STM32CubeMX.jar && \
    mkdir -p /home/${CONTAINER_USER}/STM32Cube && \
    ln -s /opt/st/Repository /home/${CONTAINER_USER}/STM32Cube/Repository

# === FIX: Pré-configurer CubeMX pour désactiver l'updater ===
RUN mkdir -p /home/${CONTAINER_USER}/.stm32cubemx && \
    echo "AutoCheckUpdates=false" > /home/${CONTAINER_USER}/.stm32cubemx/updater.prefs && \
    echo "AutoCheckFirmware=false" >> /home/${CONTAINER_USER}/.stm32cubemx/updater.prefs && \
    echo "CheckForUpdates=false" >> /home/${CONTAINER_USER}/.stm32cubemx/updater.prefs && \
    echo "UpdaterCheckPeriod=0" >> /home/${CONTAINER_USER}/.stm32cubemx/updater.prefs && \
    echo "LastCheck=9999999999999" >> /home/${CONTAINER_USER}/.stm32cubemx/updater.prefs && \
    echo "DataAutoRefresh=false" > /home/${CONTAINER_USER}/.stm32cubemx/preferences && \
    echo "OfflineMode=true" >> /home/${CONTAINER_USER}/.stm32cubemx/preferences

# Initialiser CubeMX (l'updater sera maintenant désactivé)
RUN echo "exit" > /home/${CONTAINER_USER}/cube-init && \
    (Xvfb :10 -ac > /dev/null 2>&1 &) && \
    sleep 1 && \
    export DISPLAY=:10 && \
    java -jar ${CUBE_PATH}/STM32CubeMX.jar -q /home/${CONTAINER_USER}/cube-init && \
    rm /home/${CONTAINER_USER}/cube-init && \
    pkill -f Xvfb && \
    rm -rf /tmp/.X10-lock

RUN pip install cmake --upgrade &&\
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc && \
    PATH="$HOME/.local/bin:$PATH" cmake --version && \
    pip cache purge

# Add cmake to PATH globally
ENV PATH="/home/${CONTAINER_USER}/.local/bin:$PATH"

USER root
RUN echo '#!/bin/sh\nexec java -jar /home/dev/STM32CubeMX/STM32CubeMX.jar "$@"' > /usr/bin/STM32CubeMX && \
    chmod +x /usr/bin/STM32CubeMX


#=====================================================
# CI STAGE
#=====================================================
FROM base AS ci
WORKDIR /ci
# You can add any additional tools or scripts needed for the CI here



#=====================================================
# DEV STAGE
#=====================================================
FROM base AS dev

USER root
######################################################
# LLVM-20 Installation (Clangd, Clang-Format, Clang-Tidy)
######################################################
RUN wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | gpg --dearmor -o /usr/share/keyrings/llvm-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/llvm-archive-keyring.gpg] http://apt.llvm.org/jammy/ llvm-toolchain-jammy-20 main" > /etc/apt/sources.list.d/llvm.list


######################################################
# LLVM-20 + Common Dev Tools Installation
######################################################
RUN apt-get update && apt-get install -y \
    lsb-release \
    software-properties-common \
    gnupg \
    libusb-1.0-0-dev \
    graphviz \
    default-jre \
    bash-completion \
    clang-20 \
    clangd-20 \
    clang-tidy-20 \
    clang-format-20 \
    llvm-20 \
    usbutils \
    psmisc \
    picocom \
    tree \
    sshfs \
    && apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

######################################################
# PlantUML
######################################################
RUN mkdir -p /opt/plantuml && \
    curl -o /opt/plantuml/plantuml.jar -L "https://github.com/plantuml/plantuml/releases/latest/download/plantuml.jar" && \
    printf '#!/bin/sh\nexec java -Djava.awt.headless=true -jar /opt/plantuml/plantuml.jar "$@"' > /usr/bin/plantuml && \
    chmod +x /usr/bin/plantuml

RUN update-alternatives --install /usr/bin/clang clang /usr/bin/clang-20 100 && \
    update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-20 100 && \
    update-alternatives --install /usr/bin/clangd clangd /usr/bin/clangd-20 100 && \
    update-alternatives --install /usr/bin/clang-tidy clang-tidy /usr/bin/clang-tidy-20 100 && \
    update-alternatives --install /usr/bin/clang-format clang-format /usr/bin/clang-format-20 100

######################################################
# Configure udev rules for ST-LINK
######################################################
RUN groupadd -f plugdev && \
    echo '# ST-LINK V2' > /etc/udev/rules.d/99-stlink.rules && \
    echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="3748", MODE="0666", GROUP="plugdev"' >> /etc/udev/rules.d/99-stlink.rules && \
    echo '# ST-LINK V2-1' >> /etc/udev/rules.d/99-stlink.rules && \
    echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="374b", MODE="0666", GROUP="plugdev"' >> /etc/udev/rules.d/99-stlink.rules && \
    echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="3752", MODE="0666", GROUP="plugdev"' >> /etc/udev/rules.d/99-stlink.rules && \
    echo '# ST-LINK V3' >> /etc/udev/rules.d/99-stlink.rules && \
    echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="374f", MODE="0666", GROUP="plugdev"' >> /etc/udev/rules.d/99-stlink.rules && \
    echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="3753", MODE="0666", GROUP="plugdev"' >> /etc/udev/rules.d/99-stlink.rules


######################################################
# Final User Setup
######################################################
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
USER ${CONTAINER_USER}
ENV USER=${CONTAINER_USER}
ENV PNPM_HOME="/usr/local/share/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
WORKDIR /home/${CONTAINER_USER}
RUN echo "export PATH=\"/opt/st/STLink-gdb-server/bin:\$PATH\"" >> ~/.bashrc && \
    echo "export PATH=\"/opt/st/STM32CubeProgrammer/bin:\$PATH\"" >> ~/.bashrc && \
    echo "export LANG=C.UTF-8" >> ~/.bashrc
ENTRYPOINT ["/entrypoint.sh"]
CMD [ "sleep", "infinity" ]
