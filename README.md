# DevOps Stack

Welcome to my personal project repository, where my journey with the company Stack.io has blossomed into a showcase of my seven-year tenure in the DevOps arena. This vibrant platform, initially an assignment, has evolved into a comprehensive personal blog and a demonstration of integrated DevOps, DevSecOps, and GitOps best practices using Golang and Vue.js.

The idea is to show as many options from the latest DevOps trends as possible for developing and continuously build and deploy a Golang webserver, from local to cloud deployment in a Kubernetes Cluster, with a strong focus on automation, security, scalability, reliability and future-proofing. 

The project is designed for extensibility, encouraging forks and contributions, and laying down a solid foundation for others to build upon.

**Note:** The project is still under development, with some features yet to be released publicly.

## Project Overview

What started as a Dockerized Golang Webserver and Vue.js Frontend Assignment from the company Stack.io for a Senior DevOps Engineer position, has now become the epitome of a modern DevOps workflow, emphasizing the best standards of Cloud Infrastructure with Terraform and extensive documentation to guide you at every step.

### Current State

This repository is a trove of real-world DevOps tools and implementations:

- **Local to Cloud Deployment**: Leveraging Docker, Docker Compose, and Kubernetes for versatile deployments.
- **Continuous Development**: Utilizing Skaffold, GitHub Actions and FluxCD for a seamless GitOps-driven pipeline from development to production.
- **Advanced Operations**: Incorporating Istio Service Mesh and Flagger for robust security and reliable canary deployments.
- **Monitoring & Reliability**: Integrating Prometheus and Grafana for insightful monitoring, complemented by Linkerd for logging.

### Security Focus

A core aspect of this project is its strong emphasis on security:

- **DevSecOps Tools Integration**: Embedding tools that preempt vulnerabilities and misconfigurations.
- **Secure Secrets Management**: Ensuring all secrets are encrypted and version-controlled in alignment with GitOps principles.

### Future-Proofing

The project is designed for extensibility, encouraging forks and contributions, and laying down a solid foundation for others to build upon.

## Skills & Tools Utilized

- Infrastructure as Code (IaC)
- CI/CD
- Cloud Infrastructure
- Container Orchestration
- Solution Architecture
- Programming with Go
- Frontend Development with Vue.js
- Monitoring with Prometheus and Grafana
- Cloud Platforms: Microsoft Azure, AWS
- Container & Orchestration: Docker, Kubernetes, Istio
- GitOps & DevSecOps: FluxCD, Terraform

This repository is not just a reflection of my professional skills but also a growing resource for DevOps enthusiasts and professionals alike. Dive into the code, explore the pipelines, and witness DevOps theory in action.

Feel free to fork, star, and contribute to this project. Let's build something amazing together!

## Introduction

This project serves as a practical illustration of deploying a Golang webserver to a Kubernetes cluster, encapsulating the complete lifecycle from development to deployment. At its core, it employs a Dockerfile to containerize the Go application, orchestrates the deployment via Kubernetes, and leverages Terraform for provisioning the required infrastructure on AWS. The use of extensive shell scripting throughout the process not only automates routine tasks but also ensures consistency and efficiency in the build and deployment phases. This approach highlights best practices in Infrastructure as Code (IaC), containerization, and orchestration, providing a robust blueprint for seamless integration and continuous delivery in cloud-native environments.

## MySQL Server

The app requires a MySQL Server to connect, so a directory containing the [Kubernetes templates](./kubernetes/mysql) to deploy the MySQL Server used by the app is provided for your convenience.

Alternatively, you can use the `docker-compose.yaml` file in the `dockerize` directory that contains all the services and configurations required for the app to run. This includes the MySQL server and the necessary environment variables and also creates a new _stack-io__ user and database for the app to connect to. It includes a [__mysql-init.sql__](./dockerize/mysql-init.sql) file to grant the necessary privileges to the user.

Furthermore, a [__server.config__](./dockerize/server.config) file to instruct the app to connect to the database was missing in the original files, so one was provided for the app to work. It connects to the __stack-io__ database created within the Docker Compose file with the specified credentials.

Additionally, the Docker Compose file also creates a volume to persist the data in the MySQL server and a volume to persist the logs in the app, as well as makes use of Dockerfile ARGs and ENVs instructions to demonstrate how to pass the necessary environment variables to the app.

Last but not least, you can also deploy the MySQL server using the Bitnami's Helm chart for MySQL, which is available in the [Bitnami Helm Charts repository](https://artifacthub.io/packages/helm/bitnami/mysql), using the [values.yaml](./kubernetes/mysql/helm/values.yaml) file provided.

## Dockerized Go Webserver

This repository contains a Go webserver that is designed to be run inside a Docker container.

### Prerequisites

- [Go](https://golang.org/dl/) (version 1.21.2 or later)
- [Docker](https://www.docker.com/products/docker-desktop)

### Getting Started

For more detailed information about building the app's image, read the dockerize [README.md](./dockerize/README.md) file.

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

- The Dockerfile installs the certificates for

### Further Improvements

- Create a Pre-Commit Hook to avoid commiting sensitive data.
