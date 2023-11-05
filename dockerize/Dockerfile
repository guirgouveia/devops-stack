# syntax=docker/dockerfile:1.6.0

# Demonstrates the use of ARG and ENV Dockerfile instructions
# to define the home directory of the application
# Reference: https://docs.docker.com/engine/reference/builder/#arg
# Reference: https://docs.docker.com/engine/reference/builder/#env
ARG APP_HOME=/app
ARG HTTP_PORT=8080

# Creates the build stage from the official Golang image
FROM golang:1.21.2 AS builder

ARG APP_HOME
ENV APP_HOME="$APP_HOME"

# Creates an "$APP_HOME" directory and changes the working directory to it
WORKDIR "$APP_HOME"

# Copies the go.mod and go.sum files to the "$APP_HOME" directory
COPY go.* ./

# Downloads the dependencies
RUN go mod download

# Verifies dependencies
RUN go mod verify

# Copy local code to the container image.
COPY . ./

# Builds the application
RUN go build -v -o main

# Creates a temporary folder with the files 
# to be published as an artifact to the next stage
RUN mkdir -p /tmp/output && \
    cp $APP_HOME/main /tmp/output && \
    cp $APP_HOME/config/server.confi /tmp/output && \
    cp -r $APP_HOME/src /tmp/output/src

# Creates the final stage from the official Debian slim image
FROM debian:stable-slim AS final

# Sets the ARGs and ENVs
ARG APP_HOME
ARG HTTP_PORT
ENV APP_HOME="$APP_HOME"
ENV HTTP_PORT="$HTTP_PORT"

# Set the timezone to UTC
ENV TZ=UTC

# Set the locale to en_US.UTF-8
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8
    
# Set the default shell to bash
SHELL ["/bin/sh", "-c"]

# Set the working directory
WORKDIR /app

# Copies only the necessary files from the previous stage
COPY --from=builder /tmp/output/ ./

# Install ca-certificates for HTTPS
RUN set -x && apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ca-certificates

# Optimize image and install curl for healthcheck
# Install tzdata and locales for timezone and locale configuration
RUN set -x && apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    tzdata \
    locales \
    curl && \
    rm -rf /var/lib/apt/lists/* && \
    locale-gen en_US.UTF-8 

# Create a group and user to ensure the process does not run as root
RUN groupadd -r stack-io && useradd -r -g stack-io stack-io

# Change the ownership of the /app directory to myuser
RUN chown stack-io:stack-io /app

# Switch to the new user
USER stack-io

# Exposes port 8080
EXPOSE "$HTTP_PORT"
    
# Runs the application
CMD "$APP_HOME/main"