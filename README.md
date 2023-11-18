# DevOps Stack

Welcome to my personal project repository, where my journey with the company Stack.io has blossomed into a showcase of my seven-year tenure in the DevOps arena. This vibrant platform, initially an assignment, has evolved into a comprehensive personal blog and a demonstration of integrated DevOps, DevSecOps, and GitOps best practices using Golang and Vue.js.

The idea is to show as many options from the latest DevOps trends as possible for developing and continuously build and deploy a Golang webserver, from local to cloud deployment in a Kubernetes Cluster, with a strong focus on automation, security, scalability, reliability and future-proofing. 


## Project Overview

What started as a Dockerized Golang Webserver and Vue.js Frontend Assignment from the company Stack.io for a Senior DevOps Engineer position, has now become the epitome of a modern DevOps workflow, emphasizing the best standards of Cloud Infrastructure with Terraform and extensive documentation to guide you at every step.


> **Note:** The project is still under development, with some features yet to be released publicly.
> 
> The project is designed for extensibility, encouraging forks and contributions, and laying down a solid foundation for others to build upon.
> 
> Feel free to fork, star, and contribute to this project. Let's build something amazing together!
>
> Take a look at the [RoadMap](./docs/roadmap.sh) for a glimpse of what's to come.


## Skills & Tools Utilized

- **Infrastructure as Code (IaC)**: Terraform
- **CI/CD**: GitHub Actions
- **Cloud Provideres**: Azure and AWS
- **Container Orchestration**: Docker, Kubernetes, Istio
- **Solution Architecture**: Microservices, Serverless ( Lambda, Azure Functions )
- **Programming with Go**: Golang
- **Frontend Development with Vue.js**: Vue.js
- **Monitoring with Prometheus and Grafana**: Prometheus, Grafana
- **GitOps**: FluxCD
- **DevSecOps**: Trivy & Checkov

This repository is not just a reflection of my professional skills but also a growing resource for DevOps enthusiasts and professionals alike. Dive into the code, explore the pipelines, and witness DevOps theory in action.

## Introduction

This project serves as a practical illustration of deploying a Golang webserver to a Kubernetes cluster, encapsulating the complete lifecycle from development to deployment. At its core, it employs a Dockerfile to containerize the Go application, orchestrates the deployment via Kubernetes, and leverages Terraform for provisioning the required infrastructure on AWS. The use of extensive shell scripting throughout the process not only automates routine tasks but also ensures consistency and efficiency in the build and deployment phases. This approach highlights best practices in Infrastructure as Code (IaC), containerization, and orchestration, providing a robust blueprint for seamless integration and continuous delivery in cloud-native environments.

### Security Focus

A core aspect of this project is its strong emphasis on security:

- **DevSecOps Tools Integration**: Embedding tools that preempt vulnerabilities and misconfigurations.
- **Secrets Management**: Ensuring all secrets are encrypted and version-controlled in alignment with GitOps principles.
- **Infrastructure**: Implementing security best practices in the cloud infrastructure, including network security, identity and access management, and more.
- **Containerization**: Employing best practices in containerization, including image scanning, vulnerability management, and more.
- **Deployment**: Utilizing best practices in deployment, including canary deployments, blue-green deployments, and more.
- **Monitoring**: Incorporating security best practices in monitoring, including log management, alerting, and more.
- **Development**: Implementing security best practices in development, including static code analysis, code review, and more.
