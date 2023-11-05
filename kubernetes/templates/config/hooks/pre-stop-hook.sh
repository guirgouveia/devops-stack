#!/bin/sh

set -e

echo "User $(whoami) is running pre-stop-hook.sh"

count=0
while true
do
    count=$((count+1))
    echo "User $(whoami) is checking health. Count: $count..."
    response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health)
    if [ "$response" -eq 200 ]; then
        exit 0
    fi
    sleep 5
done