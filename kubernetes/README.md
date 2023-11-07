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

Simply to illustrate how to use [Kustomize's Secret Generator](https://kubernetes.io/docs/tasks/configmap-secret/managing-secret-using-kustomize/) along with [Volume Mounts](https://kubernetes.io/docs/concepts/storage/volumes/) and [Lifecycle Hooks](https://kubernetes.io/docs/concepts/containers/container-lifecycle-hooks/), the [Lifecycle Hooks](./manifests/config/hooks) folder contains the hook scripts that will be used by Kustomize Generator to generate new ConfigMap and Secrets upon changes in the hook scripts.

The hooks are:

- **Post-Start hook**: used to verify if the database connection is ready when the application starts. The application is considered ready if it returns a 200 status code in the `/post-start-hook` endpoint.

- **Pre-Stop hook**: used to gracefully shutdown the application when the pod is terminated. The application is considered ready to be terminated if it returns a 200 status code in the `/health` endpoint.

### Pre-Stop Hook

The Pre-Stop Hook deservers a more detailed explanation as it's responsible for gracefully shutting down the application when the pod is terminated. The application is considered ready to be terminated if it passes the pre-stop hook.

As previously stated, the pre-stop hook executes a shell script loaded via a ConfigMap created with Kustomize from the [kustomization.yaml](./stack-io/kustomization.yaml) file's ConfigMap Generator. It then is mounted as a volume in the pod and the script is executed when the pod is terminated.

The pre-stop hook script defined [here](./stack-io/config/hooks/pre-stop.sh) is responsible for sending a `SIGTERM` signal to the application and waiting for it to gracefully shutdown. If the application doesn't shutdown in the specified terminationGracePeriodInSecond Deployment attribute, which is set to 60 seconds in this case, the container is killed. Notice that the pre-stop hook and the terminationGracePeriodInSecond run in parallel, so the application has 60 seconds to gracefully shutdown before it is killed, regardless of the pre-stop hook having finished or not.

Basically, the Pre-Stop Hook is responsible for the following steps:

1. **Send Request**: Send a curl request to the `/pre-stop-hook` endpoint of the application to trigger the pre-stop hook from within the webserver.

    ```bash
    response=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:8080/pre-stop-hook || echo "Pre-Stop Hook curl request failed.")
    ```

2. **Handle Pre-Stop Hook endpoint**: The webserver will then invoke the pre-stop hook endpoint handler, which will send a `SIGTERM` signal to the application and wait for it to gracefully shutdown.

    ```go
    // PreStopHookWrapper is used to adapt the PreStopHook function to the http.HandlerFunc signature.
    func PreStopHookWrapper(httpServer *http.Server) http.HandlerFunc {
        return func(w http.ResponseWriter, r *http.Request) {
            PreStopHook(w, r, httpServer)
        }
    }

    func PreStopHook(w http.ResponseWriter, r *http.Request, httpServer *http.Server) {
        // Notify the channel when a SIGTERM signal is received
        signal.Notify(gracefulStop, syscall.SIGTERM)

        // Block the execution until a SIGTERM signal is received
        <-gracefulStop
        
        ... 
        // Shutdown the server and return 200 status code if successful
        if err := httpServer.Shutdown(ctx); err != nil {
            log.Println("Pre-Stop Hook failed to gracefully shutdown the server.")
		    w.WriteHeader(http.StatusInternalServerError)
        
        ...

    }
    ```

* Notice that a Wrapper function is used to adapt the `PreStopHook` function to the `http.HandlerFunc` signature, as the `http.HandlerFunc` type is defined as `type HandlerFunc func(ResponseWriter, *Request)`, while the `PreStopHook` function is defined as `func PreStopHook(w http.ResponseWriter, r *http.Request, httpServer *http.Server)`. This was done to isolate all Kubernetes Handlers in one package to keep the project organized.

3. **Return Result to Kubernetes API**: The Pre-Stop hook will then receive a Status.OK 200 status code from the webserver and exit the script returning a Status.OK 200 status code to the Kubernetes API Server to signal that the application is ready to be terminated.

After this, the Kubernetes API Server will wait for the terminationGracePeriodInSecond to expire before killing the container, if the application hasn't already gracefully shutdown, because the Pre-Stop Hook took too long to execute. That's why we don't create long-running processes in the Pre-Stop Hook, as it will delay the termination of the pod. Usually, it's a good practice to configure the terminationGracePeriodInSecond to be at least 30 seconds longer than the time it takes for the application to gracefully shutdown by the Pre-Stop Hook.

Additionally, Pre-Stop Hooks are useful for applications that need to save state before exiting or to finish processing current requests.

### Init Container

The stack.io deployment contains two init containers. The first Init Container is called `sleep` and is used to wait for 30 seconds to wait for other services, as the MySQL Server, to be ready before the application starts.

- **Wait for 30 seconds**: The init container will wait for 30 seconds before the application starts.

    ```yaml
    initContainers:
    - name: wait-for-mysql
        image: busybox
        command: ['sh', '-c', 'sleep 30']
    ```

The other Init Container is called `setup` and prepares the files used by the application, such as making the Lifecycle Hooks executable and setting the correct permissions to the files, so that the Pod can write to the /var/logs/webserver directory.

### Post-Start Hook

The Post-Start Hook is created analogously to the Pre-Stop Hook, but it's used to send a "Hello World!" message to the webserver, that will read the body of the request and check if the message is "Hello World!" to then check if the database is ready. The post-start hook succeeds if the webserver returns a 200 status code and replies with another "Hello World!" message.

## Getting Started

The instructions below provide a step-by-step guide for setting up the application in a local Kubernetes cluster.

Both Helm Charts and Kubernetes Manifests are declared to deploy the application. The Helm Charts are located in the [helm](./helm) folder and the Kubernetes Manifests are located in the [manifests](./manifests) folder for each app of the stack.

## Prerequisites

- [Minikube](https://minikube.sigs.k8s.io/docs/start/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [MySQL Server](https://artifacthub.io/packages/helm/bitnami/mysql)
- [SOPS](https://github.com/getsops/sops)
- [Helm](https://helm.sh/docs/helm/helm_install/)
- [Helmfile](https://helmfile.readthedocs.io)
- [Skaffold](https://skaffold.dev/docs/install/#standalone-binary)
- [Kustomize](https://kubectl.docs.kubernetes.io/installation/kustomize/)
- [Docker](https://docs.docker.com/engine/install/)
- [Docker Compose](https://docs.docker.com/compose/install/linux/)
- [Go](https://go.dev/doc/install)

## Instructions

1. **Start Minikube**: Start your local Minikube cluster by running the command `minikube start`.

2. **Deploy MySQL Server**: You can deploy the Replicated StatefulSet MySQL Server with Helm Charts from the [Bitnami Helm Charts Repository](https://artifacthub.io/packages/helm/bitnami/mysql) or with Kubernetes Manifests declared in this repo to deploy a single instance MySQL Server, based on the official [Kubernetes documentation](https://kubernetes.io/docs/tasks/run-application/run-single-instance-stateful-application/).

Run all the below instructions from the kubernetes folder.

#### **Deploying with Helm**
 
 Here we have many options to deploy the Helm Chart, defining the credentials for MySQL server safely, without exposing them in the values.yaml. Only one of them is used in this repository, but I will list all of them below:
 
 - Deploy the [Bitnami MySQL Helm Chart](https://artifacthub.io/packages/helm/bitnami/mysql) with SOPS to encrypt/decrypt the file and store it safely in the repository.
 - Deploy the Helm chart with `helm secrets` plugin to decrypt the secrets before deploying the Helm Chart.
 - Use Kustomize with `helm secrets` plugin to download the Helm Charts and then patch the templated Helm Chart, for example, to add environment overlays or Secret and ConfigMap generators.
 - Deploy with Skaffold and `helm secrets` plugin
 - Define a helmfile.yaml with `helm secrets` to declare a Helm releases desired state in a declarative way.

You canf find detailed information about all these methods in the [Kubernetes Deployments Documentation](../docs/kubernetes-deployments.md) I created specifically to illustrate how to deploy applications to Kubernetes in various ways.

1. **Install Helmfile**: Install [Helmfile](

2. **Deploy the manifests**: Analogous to the previous step, you can deploy the Helm Charts from my OCI registry with the following command: 

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
    skaffold dev --keep-running-on-failure=true
    ```

This will create a pipeline that will watch for changes in the source code, as well as in the Kubernetes manifests, and continuously build and push the image to the remote registry, and deploy the app to the specified Kubernetes cluster.

After making changes to the Kubernetes manifests or source code, hit Enter in the terminal to restart the pipeline.

The application should now be accessible at http://localhost:8084, as Skaffold automatically creates a port-forward.

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
