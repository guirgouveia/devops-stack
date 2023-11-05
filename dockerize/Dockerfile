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
    cp $APP_HOME/server.confi /tmp/output && \
    cp -r $APP_HOME/src /tmp/output/src

# Creates the final stage from the official Debian slim image
FROM debian:stable-slim AS final

ARG APP_HOME
ARG HTTP_PORT
ENV APP_HOME="$APP_HOME"
ENV HTTP_PORT="$HTTP_PORT"

# Sets the working directory to the "$APP_HOME" directory
WORKDIR "$APP_HOME"

# Optimize image
RUN set -x && apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Copies only the necessary files from the previous stage
COPY --from=builder /tmp/output/ ./

RUN mv server.confi /etc/server.confi

# Exposes port 8080
EXPOSE "$HTTP_PORT"

# Runs the application
CMD "$APP_HOME/main"