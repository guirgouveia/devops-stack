# Task 2: Kubernetes Deployment

# Introduction

This document provides instructions on how to use the Kubernetes configuration files developed for deploying the Go application.

## Resources

The manifests contain the following Kubernetes resources:

- [Namespace](./manifests/namespace.yaml): The namespace where the application will be deployed.
- [Deployment](./manifests/deployment.yaml): The deployment of the application.
- [Service](./manifests/service.yaml): The service that exposes the application.
- [Ingress](./manifests/ingress.yaml): The ingress that exposes the application to the outside world.
- [Secret](./manifests/secret.yaml): The secret of the application.
- [ConfigMap](./manifests/configmap.yaml): The configuration of the application.
- [PersistentVolumeClaim](./manifests/persistentvolumeclaim.yaml): The persistent volume claim of the application.
- [Job](./manifests/job.yaml): The job that runs the database migrations.
- [CronJob](./manifests/cronjob.yaml): The cron job that runs the database backups.
- [HorizontalPodAutoscaler](./manifests/horizontalpodautoscaler.yaml): The horizontal pod autoscaler that scales the application based on CPU usage.
- [PodDisruptionBudget](./manifests/poddisruptionbudget.yaml): The pod disruption budget that ensures that at least one pod is available at all times.
- [NetworkPolicy](./manifests/networkpolicy.yaml): The network policy that restricts access to the application.
- [PodSecurityPolicy](./manifests/podsecuritypolicy.yaml): The pod security policy that restricts the privileges of the application.
- [Role](./manifests/role.yaml): The role that defines the permissions of the application.
- [RoleBinding](./manifests/rolebinding.yaml): The role binding that binds the role to the service account.
- [ServiceAccount](./manifests/serviceaccount.yaml): The service account that is used by the application.
- [PodSecurityPolicy](./manifests/podsecuritypolicy.yaml): The pod security policy that restricts the privileges of the application.

The Deployment uses the Docker image built in the previous step and includes a [readiness/liveness probe](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/), a [pre-stop hook](https://kubernetes.io/docs/concepts/containers/container-lifecycle-hooks/), and an [init container](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/) that sleeps for 30 seconds before the application starts, to ensure that the MySQL database is ready before the application starts.

## Liveness and Readiness Probes

Some modifications were done to the [webserver.go](./webserver.go) file to include endpoints for the readiness/liveness probes and the pre-stop hook.

For the liveness probe, the application is considered healthy if it returns a 200 status code in the `/health` endpoint. For the readiness probe, the application is considered ready if it returns a 200 status code in the same endpoint and the database connection is ready.**

## Lifecycle Hooks

Simply to illustrate how to use [Kustomize's Secret Generator](https://kubernetes.io/docs/tasks/configmap-secret/managing-secret-using-kustomize/) along with [Volume Mounts](https://kubernetes.io/docs/concepts/storage/volumes/) and [Lifecycle Hooks](https://kubernetes.io/docs/concepts/containers/container-lifecycle-hooks/), the [Lifecycle Hooks](./manifests/config/hooks) folder contains the hooks that will be used by Kustomize ConfigMap and Secret Generator to generate the ConfigMap and Secret that will be mounted as a Volume in the Deployment. 

The hooks are:

- **Post-Start hook**: prints a message to the console when the application starts.
- **Pre-Stop hook**: used to gracefully shutdown the application when the pod is terminated. The application is considered ready to be terminated if it returns a 200 status code in the `/health` endpoint.

## Getting Started

The instructions below provide a step-by-step guide for setting up the application in a local Kubernetes cluster.

Both Helm Charts and Kubernetes Manifests are declared to deploy the application. The Helm Charts are located in the [helm](./helm) folder and the Kubernetes Manifests are located in the [manifests](./manifests) folder for each app of the stack.

## Prerequisites

- [Minikube](https://minikube.sigs.k8s.io/docs/start/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [MySQL Server](https://artifacthub.io/packages/helm/bitnami/mysql)

## Instructions

1. **Start Minikube**: Start your local Minikube cluster by running the command `minikube start`.

2. **Deploy MySQL Server**: Deploy Bitnami's MySQL Server OCI Helm Charts in your cluster with the following command:

    ```bash
    helm upgrade --install mysql oci://registry-1.docker.io/bitnamicharts/mysql -v ./mysql-values.yaml --create-namespaces -n mysql
    ```
    or deploy it with `kubectl kustomize` running:
      
    ```bash
    kubectl apply -k mysql
    ```
The OCi registries dispenses the need of adding the helm repository to your local machine and instead downloads the chart directly from the registry. 

The `mysql-values.yaml` file contains the values that will be used to configure the MySQL Server.

1. **Deploy the manifests**: Analogous to the previous step, you can deploy the Helm Charts from my OCI registry with the following command: 

    ```bash
    helm upgrade --install stack-io oci://registry-1.docker.io/guirgouveia/stack-io -v ./mysql-values.yaml --create-namespaces -n stack-io
    ```
    or deploy it with `kubectl kustomize` running:
      
    ```bash
    kubectl apply -k stack-io
    ```

The Helm Charts are located in the [helm](./helm) folder and the Kubernetes Manifests are located in the [manifests](./manifests) folder for each app of the stack. The `kustomization.yaml` files are responsible for declaring the resources to be deployed and the automatic generation of Secrets and ConfigMaps. 

The Helm Charts are continuously built, packaged and pushed to my OCI registry at DockerHub using GitHub Actions, in order to provide the latest stable version of the application. 

In the Development stage, you can install the Helm Charts directly from the local files by running the following command:

```bash
helm install stack-io stack-io/helm/stack-io
```

1. **Verify the Deployment and Service**: You can verify that the Deployment and Service were created successfully by running the following commands:

    ```bash
    kubectl get deployments -n stack-io
    kubectl get services -n stack-io
    ```

2. **Access the Application**: If everything was set up correctly, you should be able to access the application by forwarding a port from your local machine to the Service in the cluster:

    ```
    kubectl port-forward svc/stack-io 8083:8080 -n stack-io
    ```

The application should now be accessible at http://localhost:8083.

### Using Skaffold for Development

To use Skaffold for development, make sure to install [Skaffold](https://skaffold.dev/docs/install/) and [kubectl 1.14 or higher](https://kubernetes.io/docs/tasks/tools/install-kubectl/) first.

Then, run the following command to create the pipeline that will do the local CI/CD:

    ```bash
    skaffold dev
    ```

This will create a pipeline that will watch for changes in the source code, as well as in the Kubernetes manifests, and continuously build and push the image to the remote registry, and deploy the app to the specified Kubernetes cluster.

The application should now be accessible at http://localhost:8084.

## Prerequisites

Before you begin, you will need to install the following tools:

- [Minikube](https://minikube.sigs.k8s.io/docs/start/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

## Installation

To install the application, follow these steps:

1. Start your local Minikube cluster by running the command `minikube start`.
2. Apply the `namespace.yaml` file to create a new namespace in your cluster:

    ```bash
    kubectl apply -f namespace.yaml
    ```

3. Apply the `app.yaml` file to create a new Deployment and Service in your cluster:

    ```bash
    kubectl apply -f app.yaml
    ```

4. Verify that the Deployment and Service were created successfully by running the following commands:

    ```bash
    kubectl get deployments -n stack-io
    kubectl get services -n stack-io
    ```

5. Forward a port from your local machine to the Service in the cluster:

    ```bash
    kubectl port-forward svc/stack-io 8083:8080 -n stack-io
    ```

6. Access the application by navigating to http://localhost:8083 in your web browser.

## Usage

To use the application, simply navigate to http://localhost:8083 in your web browser. The application should be up and running.

## Future Development

In the future, Kubernetes configuration files will be updated to improve the application's performance and scalability.

# Task 2: Kubernetes
### Exercise Goals

* Install minikube;
* Create namespace;
* Create deployment;
  * Use the golang webserver image you built in the previous step;
  * Add readiness/livess probe;
  * Add prestophook;
  * add init container that sleep for 30 seconds;
* Create service to expose your pod;

### Expected Output

Please, provide us with a file named `namespace.yaml` you are going to create. Your `namespace.yaml` is supposed to:
* Contain the following Kubernetes Resources you are going to create in your `minikube` cluster:
  * Namespace specification;

Please, provide us with a file named `app.yaml` you are going to create. Your `app.yaml` is supposed to:
* Contain the following Kubernetes Resources you are going to create in your `minikube` cluster:
  * Deployment specification;
    * Use your new image created on the [Task 1](../dockerize) in your deployment;
  * Service specification;

[Optional] You can also share screenshots of your progress.

### Next steps?

Once you complete this task, you can proceed to the [Terraform](../terraform) task;
