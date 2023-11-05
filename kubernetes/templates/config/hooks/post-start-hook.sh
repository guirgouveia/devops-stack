#!/bin/bash

set -e

printf "User %s is running post-start-hook.sh" "$(whoami)"

cp /etc/secrets/server.confi /app/server.confi >> /dev/null 2>&1

if [ $? -ne 0 ]; then
    printf "User %s is running post-start-hook.sh" "$(whoami)"
    exit 1
fi