terraform {
  required_version = "=1.6.2"

  backend "local" {
    path = "terraform.tfstate"
  }

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "1.11.3"
    }
  }
}

variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default = {
    "app" = "stack-io"
  }
}

locals {
  # Using this local variable to avoid repeating the namespace name
  # and creating a dependency between the namespace and the deployment
  namespace = kubernetes_deployment.main.metadata.0.namespace
}

provider "kubernetes" {
  config_path = ".kube/config"
}

resource "kubernetes_namespace" "main" {
  metadata {
    name = "stack-io"
  }
}

resource "kubernetes_service" "main" {
  metadata {
    name      = "stack-io"
    namespace = local.namespace
  }

  spec {
    selector = var.labels

    type = ClusterIP

    port {
      port        = 8080
      target_port = 8080
    }
  }
}

resource "kubernetes_manifest" "app" {
  manifest = file("../kubernetes/manifests/stack-io/app.yaml")
}

data "kubernetes_pod" "main" {
  metadata {
    namespace = local.namespace
    labels    = var.labels
  }
}

resource "null_resource" "port_forward" {
  provisioner "local-exec" {
    command = "kubectl port-forward ${data.kubernetes_pod.main.metadata.0.name} 8087:8080 -n ${local.namespace}"
  }
}