#!/bin/bash

# Log the user running the script
printf "[INFO] Running post-start-hook.sh with user %s" "$(whoami)" >> /var/logs/webserver/post-start-hook.log

# Make the POST request
max_retries=10
count=0

while [ $count -lt $max_retries ]
do
    count=$((count+1))
    printf "\n[INFO] Attempt %s of %s" "$count" "$max_retries" >> /var/logs/webserver/post-start-hook.log
    response=$(curl -X POST -H "Content-Type: application/json" -d '{"text":"Hello, World!"}' http://localhost:8080/post-start-hook)

    # Check if the response is an error (assuming a non-zero response is an error)
    if [[ "$response" -ne 0 ]] 2>/dev/null; then
        printf "\n[ERROR] Post-Start Hook failed! \n Response: %s" "$response" > /var/logs/webserver/post-start-hook.log
        printf "[ERROR] %s" "$response" >> /var/logs/post-start-hook-error
    else
        printf "\n[INFO] Post-Start Hook succeeded!" > /var/logs/webserver/post-start-hook.log
        cat /var/logs/webserver/post-start-hook.log
        exit 0
    fi

    printf "\n[INFO] Sleeping for 5 seconds..." >> /var/logs/webserver/post-start-hook.log
    sleep 5
done

printf "\n[ERROR] Max retries reached. Exiting post-start-hook with error." >> /var/logs/webserver/post-start-hook.log
exit 1