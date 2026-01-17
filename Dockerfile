FROM ubuntu:24.04

LABEL maintainer="xiahualiu"

# Non-interactive apt operations in Docker builds
ENV DEBIAN_FRONTEND=noninteractive

# Build-time arguments (can be overridden with --build-arg)
ARG STEAM_USER="steam"
ARG STEAM_HOME="/home/steam"
ARG STEAM_USER_UID=1000
ARG STEAM_USER_GID=1000
ARG STEAMCMD_DIR="${STEAM_HOME}/steamcmd"
ARG STEAM_APP_DIR="${STEAM_HOME}/game"

# Runtime environment variables derived from build args
ENV STEAM_USER=${STEAM_USER}
ENV STEAM_HOME=${STEAM_HOME}
ENV STEAMCMD_DIR=${STEAMCMD_DIR}
ENV STEAM_APP_DIR=${STEAM_APP_DIR}

# Other runtime environment variables
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Install runtime and SteamCMD dependencies, including 32-bit libs required by Steam
# Include `adduser` so `deluser`/`delgroup` are available for cleanup steps.
RUN dpkg --add-architecture i386 \
    && apt-get update && apt-get install -y --no-install-recommends \
        wget \
        curl \
        tar \
        lib32gcc-s1 \
        lib32stdc++6 \
        ca-certificates \
        locales \
        adduser \
        perl \
        # Per game server requirements
        libatomic1 \
        libpulse0 \
        libpulse-dev \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# Remove default ubuntu user to avoid conflicts
RUN deluser --remove-home ubuntu

# Create the unprivileged steam user and group with specified UID/GID
RUN groupadd -g ${STEAM_USER_GID} ${STEAM_USER} \
    && useradd -m -u ${STEAM_USER_UID} -g ${STEAM_USER_GID} -s /bin/bash ${STEAM_USER}

# Switch to the unprivileged steam user for downloads and runtime file setup
USER ${STEAM_USER}
WORKDIR ${STEAM_HOME}

# Download and extract SteamCMD into the configured directory, then run once to bootstrap
RUN mkdir -p ${STEAMCMD_DIR} \
    && curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf - -C ${STEAMCMD_DIR} \
    && ${STEAMCMD_DIR}/steamcmd.sh +quit

# Create Steam SDK symlinks used by many servers/games (64-bit and 32-bit)
RUN mkdir -p ${STEAM_HOME}/.steam/sdk64 \
    && ln -sf ${STEAMCMD_DIR}/linux64/steamclient.so ${STEAM_HOME}/.steam/sdk64/steamclient.so \
    && ln -sf ${STEAMCMD_DIR}/linux64/steamclient.so ${STEAM_HOME}/.steam/sdk64/steamservice.so \
    && ln -sf ${STEAMCMD_DIR}/linux64 ${STEAM_HOME}/.steam/bin64


# Create directories for game server files and Proton fixes configuration
RUN mkdir -p ${STEAM_APP_DIR}

# Copy the entrypoint script into the image and make it executable
COPY --chown=${STEAM_USER}:${STEAM_USER} entrypoint.sh ${STEAM_HOME}/entrypoint.sh
RUN chmod +x ${STEAM_HOME}/entrypoint.sh

# Run the entrypoint via bash to allow shell features in the script
ENTRYPOINT ["/home/steam/entrypoint.sh"]
