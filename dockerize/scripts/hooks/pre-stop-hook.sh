#!/bin/sh

set -e

while true
do
    response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health)
    if [ "$response" -eq 200 ]; then
        exit 0
    fi
    sleep 5
done