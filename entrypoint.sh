#!/bin/bash

# Exit immediately on error
set -e

# Update / install the game via SteamCMD when STEAM_APP_ID is provided.
# Anonymous login is used for most dedicated servers; use credentials if required.
if [ -n "${STEAM_APP_ID}" ]; then
    echo "--- Checking for updates (App ID: ${STEAM_APP_ID}) ---"
    ${STEAMCMD_DIR}/steamcmd.sh \
        +force_install_dir "${STEAM_APP_DIR}" \
        +login anonymous \
        +app_update "${STEAM_APP_ID}" validate \
        +quit
else
    echo "!!! Warning: STEAM_APP_ID not set. Skipping Steam update. !!!"
    exit 1
fi

# Ensure the game executable path is provided (relative to STEAM_APP_DIR)
if [ -z "${GAME_EXECUTABLE}" ]; then
    echo "ERROR: GAME_EXECUTABLE environment variable is missing."
    echo "Example: Binaries/Linux64/Server"
    exit 1
fi

echo "--- Launching ${STEAM_APP_DIR}/${GAME_EXECUTABLE} ---"

# Verify the game executable exists before launching
if [ ! -f "${STEAM_APP_DIR}/${GAME_EXECUTABLE}" ]; then
    echo "ERROR: Game executable not found at ${STEAM_APP_DIR}/${GAME_EXECUTABLE}"
    exit 1
fi

# Game specific settings
export SteamAppId=892970
export LD_LIBRARY_PATH="${STEAM_APP_DIR}/linux64:${LD_LIBRARY_PATH}"

# Run the game (exec so signals are forwarded)
exec "${STEAM_APP_DIR}/${GAME_EXECUTABLE}" $GAME_ARGS