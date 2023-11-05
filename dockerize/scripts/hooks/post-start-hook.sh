#!/bin/bash

set -e

cp /etc/secrets/server.confi /app/server.confi

if [ $? -ne 0 ]; then
    echo "User $(whoami) Failed to copy server.confi"
    exit 1
fi