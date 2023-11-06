#!/bin/sh

set -eo pipefail

printf "[INFO] Running init-setup.sh script from setup init container with user $(whoami).\n"

# Copy hooks files to another volume to be able to make them executable
printf "[INFO] Copying hooks files to /dst/ and making them executable.\n"
cp /src/* /dst/
chmod +x /dst/*

# Grant permissions to the user running the container to be able to write to the log files
printf "[INFO] Changing ownership of /var/log/webserver to user $(whoami).\n"
chown -R 999:999 /var/log/webserver