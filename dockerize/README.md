
# Task 1: Dockerize

# MySQL Server

The app requires a MySQL Server running, so use the provided [Kubernetes templates](./kubernetes/mysql) or the `docker-compose.yaml` file in the `dockerize` directory, which sets up necessary services, environment variables, and user privileges.

An initial *blog* database is created for storing blog posts, but it's empty as no content is provided by the assigner. 

The Docker Compose file also sets up volumes for data and log persistence, and demonstrates passing environment variables using Dockerfile ARGs and ENVs instructions.

# Additional Packages

A [Kubernetes Handler Golang package](./webserver/kuberneteshandler/) was created to handle Kubernetes events, such as the ones triggered by the Kubernetes liveness, readiness probes and the lifecycle hooks.

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

The *($1)* app before running the container, to reflect any changes made to the source code.

Now, you can access the webserver at `http://localhost:8081`, because the docker-compose file maps port 8080 inside the Docker container to port 8081 on your local machine to avoid conflicts with services running on port 8080.

The *($1)* to pass the necessary configurations to the app, such as the database credentials and the database name.

The image can also be built and pushed to a Docker registry, such as Docker Hub, to be used by the Kubernetes cluster in the next task, with:

```
docker-compose build --push
```

### Using Skaffold for Development

To use Skaffold for development, make sure to install [Skaffold](https://skaffold.dev/docs/install/) and [kubectl 1.14 or higher](https://kubernetes.io/docs/tasks/tools/install-kubectl/) first.

Then, run the following command to create the pipeline that will do the local CI/CD:

    ```bash
    skaffold dev
    ```

This will create a pipeline that will watch for changes in the source code, as well as in the Kubernetes manifests, and continuously build and push the image to the remote registry, and deploy the app to the specified Kubernetes cluster.

### About the Docker Image

A Multi-stage build is used to create a small Docker image. The Dockerfile contains two stages:

- The builder stage builds the Go binary.
- The runner stage copies only the Go binary from the builder stage and runs it.

The final stage is based on a slim Debian image that contains only the bare minimum to run the Go binary.
Furthermore, the following configurations are applied:

- The Dockerfile installs the certificates for the CA certificates in the builder stage. This is required to make HTTPS calls.
- The Dockerfile removes the apt cache to reduce the image size. This is done in the same layer as the apt-get install command to reduce the image size.

# Task 1: Dockerize
### Exercise Goals

This is your first task in out assignment. Here you are supposed to build a Dockfile with a Go Webserver within. 

* Create a `Dockerfile`;
  * Build `golang` executable inside your `Dockerfile`;
  * Let the executable run as you load the image;
* Build a `Docker` image using your `Dockerfile`;
* Run your new created image and get a `200` HTTP Code once your container is running;

### Expected Output

Please, provide us with the `Dockerfile` you created. Your `Dockerfile` is supposed to:
* Copy our source code inside this folder to the image;
* Build the binary from our source code inside the image;
* Run the binary at the end of the image;

[Optional] You can also share screenshots of your progress.

### Next steps?

Once you complete this task, you can proceed to the [Kubernetes](../kubernetes) task;