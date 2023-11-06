#!/bin/sh

set -e

printf "[INFO] Pre-stop hook initiated with user %s.\n" "$(whoami)" >> /var/logs/webserver/pre-stop-hook.log

max_retries=10
count=0

while [ $count -lt $max_retries ]
do
    count=$((count+1))
    printf "Checking /shutdown endpoint. Attempt: %s\n" "$count"
    
    response=$(curl -X POST http://localhost:8080/pre-stop-hook || echo "Pre-Stop Hook curl request failed.")
    
    if [ "$response" = "Curl failed" ]; then
        printf "Failed to reach /shutdown endpoint. Attempt: %s\n" "$count" >> /var/logs/webserver/pre-stop-hook.log
    elif [ "$response" -eq 200 ]; then
        printf "Pre-Stop Hook executed succesfully. \n" >> /var/logs/webserver/pre-stop-hook.log
        exit 0
    else
        printf "Pre-Stop Hook failed. %s. Retrying...\n" "$response" >> /var/logs/webserver/pre-stop-hook.log
    fi

    printf "Sleeping for 5 seconds...\n" >> /var/logs/webserver/pre-stop-hook.log
    
    sleep 5
done

printf "Max retries reached. Exiting pre-stop hook with error.\n" >> /var/logs/webserver/pre-stop-hook.log
exit 1