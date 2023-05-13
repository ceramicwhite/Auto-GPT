#!/bin/bash

set -e

PLUGINS_PATH="/app/plugins"

# Ensure the plugins directory exists
mkdir -p ${PLUGINS_PATH}

if [ -z "$PLUGINS" ]
then
      echo "No plugins specified. Skipping download."
else
    # Split the plugins list into an array
    IFS=',' read -r -a plugin_array <<< "$PLUGINS"

    # Download each plugin
    for element in "${plugin_array[@]}"
    do
        # Extract the plugin name from the string (everything after the last /)
        PLUGIN_NAME=$(basename "$element")
        # Form the full URL
        FULL_URL="https://github.com/${element}/archive/refs/heads/master.zip"
        # Download the plugin
        curl -L -o ${PLUGINS_PATH}/"${PLUGIN_NAME}".zip "$FULL_URL"
    done

    # Install plugin dependencies
    python -m scripts.install_plugin_deps
fi

# Install plugin requirements
if [ ! -z "$PLUGINS_REQS" ]
then
    # Split the requirements list into an array
    IFS=',' read -r -a reqs_array <<< "$PLUGINS_REQS"

    # Install each requirement
    for element in "${reqs_array[@]}"
    do
        echo "Installing $element"
        if pip install --no-cache-dir "$element"; then
            echo "Installed $element with pip"
        elif apt-get -y install "$element"; then
            echo "Installed $element with apt-get"
        else
            echo "Failed to install $element"
        fi
    done
fi

# Base command
COMMAND=("gotty" "--port" "3000" "--permit-write" "--title-format" "AutoGPT Terminal" "python" "-m" "autogpt")

# Check GPT3_ONLY environment variable
if [ "$GPT3_ONLY" = true ]
then
    COMMAND+=("--gpt3only")
    export FAST_TOKEN_LIMIT=4000
    export SMART_TOKEN_LIMIT=4000
    export BROWSE_CHUNK_MAX_LENGTH=3000
fi

# Execute the original ENTRYPOINT with all arguments
exec "${COMMAND[@]}"
