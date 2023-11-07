# Terraform

# Introduction to Terraform

Terraform is an open-source infrastructure as code software tool created by HashiCorp. It enables users to define and provision a datacenter infrastructure using a high-level configuration language known as Hashicorp Configuration Language, or optionally JSON.

# Backend

Responsible for storing Terraform state. The state is used by Terraform to map real world resources to your configuration, keep track of metadata, and to improve performance for large infrastructures.

## Local

The local backend stores state on the local filesystem. This backend is ideal for local development and does not require access to remote services or credentials.

You can use other backends to store the state file remotely, with lock management to prevent corruption and concurrent modifications. See [Backends](https://www.terraform.io/docs/language/settings/backends/index.html) for more information.

# Providers

A provider is responsible for understanding API interactions and exposing resources. Providers generally are an IaaS (e.g. Alibaba Cloud, AWS, GCP, Microsoft Azure, OpenStack), PaaS (e.g. Heroku), or SaaS services (e.g. Terraform Cloud, DNSimple, CloudFlare).

## Kubernetes Provider

The Kubernetes provider is used to interact with the resources supported by Kubernetes. The provider needs to be configured with the proper credentials before it can be used.

# Getting Started

This module will guide you through the basics of Terraform. You will learn how to create a Terraform script to deploy a Kubernetes application.

## Prerequisites

* [Terraform](https://www.terraform.io/downloads.html) installed;
* [Minikube](https://minikube.sigs.k8s.io/docs/start/) installed;

## Deploying a Kubernetes application

The main.tf file declares a Kubernetes provider and a Kubernetes deployment. The provider is configured to connect to your minikube context, using your local .kube/config.

# Task 3: Terraform
### Exercise Goals

* Create a Terraform script named `main.tf` to:
  * Use the local backend;
  * Use the [Kubernetes Provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest);
  * Connect to your `minikube` context, using your local `.kube/config;
  * Load the `app.yaml` from your last task in this module and apply it to your `minukube` context;
* Init your terraform script;
* Apply your terraform script;

### Expected Output

Please, provide us with the `main.tf` you created. Your `main.yaml` is supposed to:
* Use local backend;
* Use the Kubernetes Provider mentioned before;
* Apply your `app.yaml` to your minikube;

Please, provide us with the `terraform.state` file that was created when you ran `terraform apply`;

[Optional] You can also share screenshots of your progress.

### Next steps?

Once you complete this task, you can proceed to the [Linux](../linux) task;
