# Introduction

This project began as an assignment from Stack.io for a Senior DevOps role, but as I delved into Golang and Vue.js to create a personal blog, it turned into a vibrant platform to showcase my seven years of DevOps expertise, integrating DevSecOps and GitOps best practices.

Initially, the focus was on developing and dockerizing a Golang Webserver and a Vue.js Frontend. The deployment process was handled with Docker, Docker Compose, and Kubernetes, both locally and on the cloud. Terraform played a significant role in molding the cloud infrastructure, adhering to Cloud Infrastructure's best standards.

Though still a work in progress with some implementations yet to be shared on the public repository, it's a treasure trove of tools and DevOps implementations.

I incorporated Skaffold pipelines for streamlined local development, and with FluxCD, forged a GitOps route for continuous app deployments across dev, staging, and production environments within the cluster. Additionally, Istio Service Mesh and Flagger were introduced for enhanced cluster security and canary deployments. The monitoring aspects were enriched with SRE elements through Prometheus and Grafana, while Linkerd addressed logging.

To bolster security, a range of DevSecOps tools were integrated, safeguarding against vulnerabilities and misconfigurations, and ensuring encrypted and version-controlled secrets in the repository, all in tune with GitOps best practices.

The project is thoroughly documented, with guides, roadmaps, and suggestions for future enhancements dispersed across folders. Its design enables anyone to fork it and embark on developing their own app stack, building on the solid foundation I've laid down.

**Skills & Tools**: Infrastructure as code (IaC) · Continuous Integration and Continuous Delivery (CI/CD) · Cloud Infrastructure · Container Orchestration · Solution Architecture · Go (Programming Language) · Vue.js · FluxCD · Prometheus · Microsoft Azure · DevSecOps · GitOps · Terraform · Kubernetes · AWS · Docker · Istio · Grafana

# MySQL Server

The app requires a MySQL Server to connect, so a directory containing the [Kubernetes templates](./kubernetes/mysql) to deploy the MySQL Server used by the app is provided for your convenience.

Alternatively, you can use the `docker-compose.yaml` file in the `dockerize` directory that contains all the services and configurations required for the app to run. This includes the MySQL server and the necessary environment variables and also creates a new _stack-io__ user and database for the app to connect to. It includes a [__mysql-init.sql__](./dockerize/mysql-init.sql) file to grant the necessary privileges to the user.

Furthermore, a [__server.confi__](./dockerize/server.confi) file to instruct the app to connect to the database was missing in the original files, so one was provided for the app to work. It connects to the __stack-io__ database created within the Docker Compose file with the specified credentials.

Additionally, the Docker Compose file also creates a volume to persist the data in the MySQL server and a volume to persist the logs in the app, as well as makes use of Dockerfile ARGs and ENVs instructions to demonstrate how to pass the necessary environment variables to the app.


## Dockerized Go Webserver

This repository contains a Go webserver that is designed to be run inside a Docker container.

### Prerequisites

- [Go](https://golang.org/dl/) (version 1.21.2 or later)
- [Docker](https://www.docker.com/products/docker-desktop)

### Getting Started

Before building the Docker image, make sure to tidy up the Go modules from the [dockerize](./dockerize) directory:

```bash
go mod tidy
```

This command will ensure that your `go.mod` and `go.sum` files are up to date.

### Building the Docker Image

To build the Docker image, navigate to the [dockerize](./dockerize) directory containing the `Dockerfile` and run:

```bash
docker build -t stack-io .
```

This command builds a Docker image and tags it as `stack-io`.

### Running the Docker Container

To run the Docker container, use the following command:

```bash
docker run -p 8080:8080 stack-io
```

This command runs the Docker container and maps port 8080 inside the Docker container to port 8080 on your local machine.

Now, you can access the webserver at `http://localhost:8080`, if the dependencies are met.

### Running the App with Docker Compose

As the app has dependencies on other services, such as a MySQL server, a Docker Compose file is provided for your convenience.

To run the app using Docker Compose, navigate to the `dockerize` directory containing the `docker-compose.yaml` file and run:

```bash
docker-compose up --build
```

The __build__ flag is used to build a new Docker image for the __stack-io__ app before running the container, to reflect any changes made to the source code.

Now, you can access the webserver at `http://localhost:8081`, because the docker-compose file maps port 8080 inside the Docker container to port 8081 on your local machine to avoid conflicts with services running on port 8080.

The __docker-compose.yaml__ uses environment variables from the __.env__ to pass the necessary configurations to the app, such as the database credentials and the database name.

The image can also be pushed to a Docker registry, such as Docker Hub, to be used by the Kubernetes cluster in the next task, with:

```
docker-compose push
```

### About the Docker Image

A Multi-stage build is used to create a small Docker image. The Dockerfile contains two stages:

- The builder stage builds the Go binary.
- The runner stage copies only the Go binary from the builder stage and runs it.

The final stage is based on a slim Debian image that contains only the bare minimum to run the Go binary.
Furthermore, the following configurations are applied:

- The Dockerfile installs the certificates for the CA certificates in the builder stage. This is required to make HTTPS calls.
- The Dockerfile removes the apt cache to reduce the image size. This is done in the same layer as the apt-get install command to reduce the image size.



# Guideline

Welcome to our `Take Home Assingment`. We are going to provide you with a sequence of tasks to be executed:
* [Task 1](dockerize): Dockerize a simple golang webserver; You do not need to modify or write any golang code. You do not need to be familiar with the golang language either, just with how to manipulate and use an already written golang app.
* [Task 2](kubernetes): Deploy that docker image to your local k8s cluster following the given spec
* [Task 3](terraform): Create a terraform module
* [Task 4](linux): Write down a shell script for further automation

# Task 1: Dockerize

