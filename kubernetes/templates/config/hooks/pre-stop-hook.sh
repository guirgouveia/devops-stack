#!/bin/sh

set -e

echo "Pre-stop hook initiated by $(whoami)"

max_retries=10
count=0

while [ $count -lt $max_retries ]
do
    count=$((count+1))
    echo "Checking /shutdown endpoint. Attempt: $count"
    
    response=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:8080/shutdown || echo "Curl failed")
    
    if [ "$response" = "Curl failed" ]; then
        echo "Failed to reach /shutdown endpoint. Attempt: $count"
    elif [ "$response" -eq 200 ]; then
        echo "/shutdown endpoint returned 200. Exiting pre-stop hook."
        exit 0
    else
        echo "/shutdown endpoint returned $response. Retrying..."
    fi

    printf "Sleeping for 5 seconds..."
    
    sleep 5
done

echo "Max retries reached. Exiting pre-stop hook with error."
exit 1