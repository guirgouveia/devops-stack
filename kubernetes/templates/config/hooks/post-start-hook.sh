#!/bin/bash

set -e

echo "User $(whoami) is running post-start-hook.sh"

echo "User $(whoami) is copying server.confi"
cp /etc/secrets/server.confi /app/server.confi

if [ $? -ne 0 ]; then
    echo "User $(whoami) Failed to copy server.confi"
    exit 1
fi