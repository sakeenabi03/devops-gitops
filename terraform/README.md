# Terraform Kubernetes Infrastructure

This directory contains the Terraform configuration used to provision and manage Kubernetes resources for the **Automated Kubernetes Deployment Platform Using Terraform & GitOps** project.

The project demonstrates how Infrastructure as Code (IaC) can be used together with Kubernetes, Helm, GitHub Actions, Argo CD, Prometheus, and Grafana to build a complete DevOps workflow.

Terraform is responsible for managing supporting Kubernetes infrastructure, while the main application deployment is handled through Helm and Argo CD using a GitOps workflow.

---

## Table of Contents

* [Project Overview](#project-overview)
* [Role of Terraform](#role-of-terraform)
* [Architecture](#architecture)
* [Terraform Directory Structure](#terraform-directory-structure)
* [Resources Managed by Terraform](#resources-managed-by-terraform)
* [Terraform Configuration](#terraform-configuration)
* [Terraform Variables](#terraform-variables)
* [Terraform Outputs](#terraform-outputs)
* [Kubernetes Resources](#kubernetes-resources)
* [Prerequisites](#prerequisites)
* [Clone the Repository](#clone-the-repository)
* [Verify the Kubernetes Cluster](#verify-the-kubernetes-cluster)
* [Initialize Terraform](#initialize-terraform)
* [Format Terraform Configuration](#format-terraform-configuration)
* [Validate Terraform Configuration](#validate-terraform-configuration)
* [Review the Execution Plan](#review-the-execution-plan)
* [Apply the Infrastructure](#apply-the-infrastructure)
* [View Terraform Outputs](#view-terraform-outputs)
* [Verify Kubernetes Resources](#verify-kubernetes-resources)
* [Inspect Individual Resources](#inspect-individual-resources)
* [Test the Kubernetes Service](#test-the-kubernetes-service)
* [Modify Terraform Variables](#modify-terraform-variables)
* [Terraform State](#terraform-state)
* [Terraform Workflow](#terraform-workflow)
* [Destroy Terraform Resources](#destroy-terraform-resources)
* [Project Integration](#project-integration)
* [Tool Responsibilities](#tool-responsibilities)
* [Troubleshooting](#troubleshooting)
* [Important Notes](#important-notes)

---

# Project Overview

The project implements a DevOps platform that combines:

* Containerization
* Automated testing
* Docker image creation
* Container security scanning
* Container image publishing
* Infrastructure as Code
* Kubernetes
* Helm
* GitOps
* Argo CD
* Monitoring and observability

The overall workflow is:

```text
Developer
    |
    | git push
    v
GitHub
    |
    v
GitHub Actions
    |
    +---- Run Tests
    |
    +---- Build Docker Image
    |
    +---- Trivy Security Scan
    |
    +---- Push Image to GHCR
    |
    v
GitOps Repository
    |
    v
Argo CD
    |
    v
Kubernetes / Kind
    |
    +---- Helm Application Deployment
    |
    +---- Terraform Managed Infrastructure
    |
    v
Prometheus + Grafana
```

---

# Role of Terraform

Terraform is used as the **Infrastructure as Code (IaC)** tool in this project.

Instead of manually creating Kubernetes resources using commands such as:

```bash
kubectl create namespace
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

the Kubernetes resources can be described declaratively using Terraform configuration files.

Terraform compares the desired configuration with its state and the current infrastructure and determines what changes are required.

The Terraform configuration in this project manages:

* Kubernetes namespace
* Kubernetes ConfigMap
* Kubernetes Deployment
* Kubernetes Service
* Application replicas
* Container image
* CPU and memory requests
* CPU and memory limits
* Readiness probe
* Liveness probe

---

# Architecture

Terraform manages Kubernetes resources inside an already-running Kind cluster.

```text
                    Terraform
                        |
                        v
              Kubernetes Provider
                        |
                        v
                Kubernetes API
                        |
                        v
                 Kind Cluster
                        |
             +----------+----------+
             |                     |
             v                     v
      terraform-demo         Other project
        namespace             components
             |
       +-----+-----+
       |           |
       v           v
   Deployment   ConfigMap
       |
       +----------------+
       |                |
       v                v
   NGINX Pod         NGINX Pod
       |
       v
   ClusterIP Service
```

The Kind cluster itself is not currently created by Terraform. Terraform connects to the existing Kubernetes cluster using the Kubernetes provider and the local kubeconfig file.

---

# Terraform Directory Structure

The Terraform directory contains the following configuration files:

```text
terraform/
│
├── main.tf
├── variables.tf
├── outputs.tf
├── README.md
│
├── terraform.tfstate
└── .terraform/
```

### `main.tf`

Contains the main Terraform configuration, including:

* Terraform provider configuration
* Kubernetes namespace
* ConfigMap
* Deployment
* Service
* Container configuration
* Resource requests and limits
* Readiness probe
* Liveness probe

### `variables.tf`

Contains reusable input variables such as:

* Namespace name
* Application name
* ConfigMap name
* Replica count
* Container image

### `outputs.tf`

Defines useful information that Terraform displays after deployment, such as:

* Namespace
* Application name
* Container image
* Replica count
* Service name

### `terraform.tfstate`

Terraform uses the state file to track resources that it manages.

The state allows Terraform to understand the relationship between the Terraform configuration and the resources already created in Kubernetes.

> **Important:** `terraform.tfstate` may contain infrastructure information and should generally not be committed to a public repository. A `.gitignore` file should be used to exclude Terraform state and local Terraform files.

---

# Resources Managed by Terraform

## 1. Kubernetes Namespace

Terraform creates and manages the namespace:

```text
terraform-demo
```

This namespace provides an isolated logical area for the Terraform-managed resources.

The Terraform resource is:

```hcl
resource "kubernetes_namespace" "terraform_demo"
```

The namespace name is controlled through the Terraform variable:

```hcl
var.namespace_name
```

Default value:

```text
terraform-demo
```

---

## 2. Kubernetes ConfigMap

Terraform manages a ConfigMap named:

```text
devops-demo-config
```

The ConfigMap contains application-related configuration:

```text
APP_NAME    = devops-demo
ENVIRONMENT = local
MANAGED_BY  = terraform
```

The ConfigMap demonstrates how non-sensitive application configuration can be stored separately from container images and application code.

Sensitive information such as passwords, API keys, and credentials should not be stored directly in a ConfigMap.

---

## 3. Kubernetes Deployment

Terraform manages an NGINX Deployment:

```text
terraform-demo
```

The Deployment is configured with:

```text
Replicas: 2
Image: nginx:1.27
Container Port: 80
```

The Deployment ensures that the desired number of application Pods are running.

If a Pod fails, Kubernetes can create a replacement Pod according to the Deployment configuration.

---

## 4. Resource Requests and Limits

The NGINX container has CPU and memory configuration.

### Requests

```text
CPU:    100m
Memory: 64Mi
```

Requests represent the amount of CPU and memory Kubernetes should reserve for scheduling the Pod.

### Limits

```text
CPU:    250m
Memory: 128Mi
```

Limits define the maximum CPU and memory resources available to the container.

This demonstrates basic Kubernetes resource management through Terraform.

---

## 5. Readiness Probe

The Deployment includes a readiness probe:

```text
Path: /
Port: 80
Initial Delay: 5 seconds
Period: 10 seconds
```

The readiness probe checks whether the NGINX container is ready to receive traffic.

If the readiness check fails, Kubernetes can prevent the Pod from receiving traffic through the Service until it becomes ready.

---

## 6. Liveness Probe

The Deployment also includes a liveness probe:

```text
Path: /
Port: 80
Initial Delay: 10 seconds
Period: 20 seconds
```

The liveness probe helps Kubernetes determine whether the container is still functioning.

If the liveness check continuously fails, Kubernetes can restart the affected container.

---

## 7. Kubernetes Service

Terraform creates a Kubernetes Service:

```text
terraform-demo
```

The Service type is:

```text
ClusterIP
```

The Service exposes the NGINX application internally within the Kubernetes cluster.

Configuration:

```text
Port:        80
Target Port: 80
Protocol:    TCP
Type:        ClusterIP
```

The Service selects Pods using the label:

```text
app: terraform-demo
```

---

# Terraform Configuration

The Terraform Kubernetes provider connects Terraform to the Kubernetes cluster.

The provider configuration is:

```hcl
provider "kubernetes" {
  config_path = "~/.kube/config"
}
```

This tells Terraform to use the local Kubernetes configuration file.

The Kubernetes context must point to the intended cluster before running Terraform commands.

---

# Terraform Variables

The configuration uses variables to avoid hardcoding values throughout the Terraform configuration.

The following variables are currently defined:

| Variable          | Description                    | Default              |
| ----------------- | ------------------------------ | -------------------- |
| `namespace_name`  | Kubernetes namespace           | `terraform-demo`     |
| `app_name`        | Application name               | `terraform-demo`     |
| `config_map_name` | ConfigMap name                 | `devops-demo-config` |
| `replica_count`   | Number of application replicas | `2`                  |
| `container_image` | Container image                | `nginx:1.27`         |

For example, the replica count is controlled by:

```hcl
replicas = var.replica_count
```

The container image is controlled by:

```hcl
image = var.container_image
```

This allows the configuration to be changed without modifying the resource definitions directly.

---

# Terraform Outputs

The configuration provides outputs for:

* Kubernetes namespace
* Application name
* Container image
* Replica count
* Service name

Run:

```bash
terraform output
```

Example:

```text
application_name = "terraform-demo"
container_image  = "nginx:1.27"
namespace        = "terraform-demo"
replica_count    = 2
service_name     = "terraform-demo"
```

Outputs provide a convenient way to retrieve important information from Terraform after deployment.

---

# Prerequisites

Before using this Terraform configuration, install the following tools.

## Terraform

Terraform is used for Infrastructure as Code.

Verify the installation:

```bash
terraform version
```

---

## Docker

Docker is required because the Kubernetes cluster is running locally using Kind.

Verify Docker:

```bash
docker --version
```

Make sure Docker Desktop is running.

---

## Kind

Kind runs Kubernetes clusters using Docker containers.

Verify Kind:

```bash
kind version
```

---

## kubectl

kubectl is used to interact with the Kubernetes cluster.

Verify:

```bash
kubectl version --client
```

---

# Clone the Repository

Clone the GitOps repository:

```bash
git clone <YOUR_GITHUB_REPOSITORY_URL>
```

Move into the repository:

```bash
cd devops-gitops
```

Move into the Terraform directory:

```bash
cd terraform
```

> Replace `<YOUR_GITHUB_REPOSITORY_URL>` with the actual GitHub repository URL.

---

# Verify the Kubernetes Cluster

Terraform in this project expects an existing Kind cluster.

Check the available Kubernetes contexts:

```bash
kubectl config get-contexts
```

Check the current context:

```bash
kubectl config current-context
```

The expected context for this project is:

```text
kind-devops-cluster
```

If the context is correct, verify the cluster:

```bash
kubectl get nodes
```

Example:

```text
NAME                       STATUS   ROLE           AGE
devops-cluster-control-plane   Ready    control-plane   ...
```

The cluster must be running before Terraform can communicate with Kubernetes.

---

# Initialize Terraform

From the Terraform directory, run:

```bash
terraform init
```

Terraform downloads the required provider and prepares the working directory.

This project uses the HashiCorp Kubernetes provider:

```text
hashicorp/kubernetes
```

The configuration currently uses version constraint:

```text
~> 2.38
```

---

# Format Terraform Configuration

Run:

```bash
terraform fmt
```

This formats Terraform configuration files according to Terraform's standard formatting conventions.

---

# Validate Terraform Configuration

Run:

```bash
terraform validate
```

A successful validation should return:

```text
Success! The configuration is valid.
```

Validation checks the syntax and internal consistency of the Terraform configuration.

---

# Review the Execution Plan

Before applying infrastructure changes, review the Terraform plan:

```bash
terraform plan
```

Terraform compares the desired configuration with the current Terraform state and Kubernetes resources.

The plan shows whether Terraform intends to:

```text
+ create
~ update
- destroy
```

For example:

```text
Plan: 0 to add, 1 to change, 0 to destroy.
```

Always review the plan before applying changes.

---

# Apply the Infrastructure

To create or update the Kubernetes resources:

```bash
terraform apply
```

Terraform displays the planned changes.

Review the plan and enter:

```text
yes
```

when prompted.

Terraform will then create or update the configured Kubernetes resources.

---

# View Terraform Outputs

After applying the configuration, run:

```bash
terraform output
```

This displays the values defined in `outputs.tf`.

For example:

```text
application_name = "terraform-demo"
container_image  = "nginx:1.27"
namespace        = "terraform-demo"
replica_count    = 2
service_name     = "terraform-demo"
```

---

# Verify Kubernetes Resources

After applying Terraform, verify the resources directly through Kubernetes.

## Check Namespace

```bash
kubectl get namespace terraform-demo
```

---

## Check Deployment

```bash
kubectl get deployment -n terraform-demo
```

Expected result:

```text
NAME              READY   UP-TO-DATE   AVAILABLE
terraform-demo    2/2     2            2
```

---

## Check Pods

```bash
kubectl get pods -n terraform-demo
```

The Pods should eventually show:

```text
Running
```

Example:

```text
terraform-demo-xxxxxxxxxx-xxxxx   1/1   Running
terraform-demo-xxxxxxxxxx-xxxxx   1/1   Running
```

---

## Check Service

```bash
kubectl get service -n terraform-demo
```

Expected configuration:

```text
NAME              TYPE        CLUSTER-IP     PORT(S)
terraform-demo    ClusterIP   ...            80/TCP
```

---

## Check ConfigMap

```bash
kubectl get configmap -n terraform-demo
```

To view its contents:

```bash
kubectl describe configmap devops-demo-config -n terraform-demo
```

---

# Inspect Individual Resources

## Inspect Deployment

```bash
kubectl describe deployment terraform-demo -n terraform-demo
```

This can be used to verify:

* Replica count
* Container image
* Resource requests
* Resource limits
* Readiness probe
* Liveness probe
* Deployment conditions

---

## Inspect Pods

```bash
kubectl describe pods -n terraform-demo
```

This is useful when troubleshooting Pod scheduling, startup, readiness, or container issues.

---

## Inspect Service

```bash
kubectl describe service terraform-demo -n terraform-demo
```

This displays the Service configuration and selected endpoints.

---

# Test the Kubernetes Service

Because the Service is a `ClusterIP`, it is intended for internal Kubernetes communication.

You can use port forwarding to access the NGINX application locally:

```bash
kubectl port-forward service/terraform-demo -n terraform-demo 8081:80
```

Then open:

```text
http://localhost:8081
```

You should see the NGINX welcome page.

Stop the port-forwarding process with:

```text
Ctrl + C
```

---

# Modify Terraform Variables

One of the benefits of Terraform variables is that infrastructure configuration can be changed without modifying the resource definitions.

For example, the default replica count is:

```hcl
variable "replica_count" {
  default = 2
}
```

You can temporarily override the value from the command line:

```bash
terraform plan -var="replica_count=3"
```

To apply that change:

```bash
terraform apply -var="replica_count=3"
```

Terraform will determine the required Kubernetes changes.

The same approach can be used with other variables.

For example:

```bash
terraform plan -var="container_image=nginx:1.28"
```

This allows the same Terraform configuration to be reused with different infrastructure values.

---

# Terraform State

Terraform maintains a state file to track resources under its management.

The main state file is:

```text
terraform.tfstate
```

Terraform uses this state to determine:

* Which resources it manages
* Current resource information
* Resource relationships
* Changes required during future plans and applies

For a team or production environment, remote state storage is generally preferred over storing state locally.

For this local portfolio project, Terraform state is used locally.

Do not commit sensitive Terraform state to a public repository.

A `.gitignore` should exclude:

```text
.terraform/
*.tfstate
*.tfstate.*
```

---

# Terraform Workflow

The standard Terraform workflow used in this project is:

```text
Write Configuration
       |
       v
terraform fmt
       |
       v
terraform validate
       |
       v
terraform plan
       |
       v
Review Changes
       |
       v
terraform apply
       |
       v
Kubernetes Resources
```

When infrastructure needs to be changed, repeat the workflow.

For example:

```bash
terraform fmt
terraform validate
terraform plan
terraform apply
```

---

# Terraform and Kubernetes Responsibilities

Terraform and Kubernetes have different responsibilities.

Terraform defines the desired infrastructure configuration.

Kubernetes is responsible for actually running and managing the workloads.

For example:

```text
Terraform
    |
    | Desired configuration
    v
Kubernetes API
    |
    v
Kubernetes Controller
    |
    v
Pods / Services / Deployments
```

Terraform does not replace Kubernetes.

Instead, Terraform provides an Infrastructure as Code approach for managing Kubernetes resources.

---

# Terraform vs Helm in This Project

Terraform and Helm are both used in the overall project, but they serve different purposes.

## Terraform

Terraform manages supporting Kubernetes infrastructure and demonstrates Infrastructure as Code.

Current Terraform-managed resources include:

* Namespace
* ConfigMap
* NGINX Deployment
* Kubernetes Service
* Resource configuration
* Health probes

## Helm

Helm packages the main application deployment as a reusable Kubernetes chart.

The application Helm chart contains:

* Deployment
* Service
* Application configuration
* Image configuration
* Replica configuration
* Health probes

This separation allows Terraform and Helm to demonstrate different infrastructure and application deployment approaches.

---

# Terraform and Argo CD

Argo CD is responsible for GitOps-based continuous delivery of the main application.

The overall workflow is:

```text
GitHub
   |
   v
GitOps Repository
   |
   v
Argo CD
   |
   v
Helm
   |
   v
Kubernetes
```

Terraform is separate from this application deployment workflow.

Terraform manages its defined Kubernetes infrastructure resources through the Kubernetes API.

This project therefore demonstrates both:

```text
Infrastructure as Code
        +
GitOps Continuous Delivery
```

---

# Destroy Terraform Resources

If the Terraform-managed resources are no longer required, they can be removed using:

```bash
terraform destroy
```

Terraform will show the resources that are going to be removed.

Review the plan carefully and enter:

```text
yes
```

when prompted.

> **Important:** `terraform destroy` removes resources managed by this Terraform configuration. It does not mean that all resources in the Kubernetes cluster will be deleted.

For example, the separately managed Argo CD, monitoring stack, and other Kubernetes resources are not automatically removed by this Terraform configuration.

---

# Project Integration

Terraform is one component of the overall DevOps platform.

The project uses separate tools for different stages of the software delivery lifecycle.

```text
                    Developer
                        |
                        v
                    GitHub
                        |
                        v
               GitHub Actions
                        |
             +----------+----------+
             |          |           |
             v          v           v
           Tests      Docker      Trivy
                        |
                        v
                      GHCR
                        |
                        v
                 GitOps Repository
                        |
                        v
                    Argo CD
                        |
                        v
                  Kubernetes
                  /         \
                 /           \
                v             v
           Helm App       Terraform
                |             |
                +------+------+
                       |
                       v
                 Kind Cluster
                       |
                       v
              Prometheus + Grafana
```

---

# Tool Responsibilities

| Tool             | Responsibility                     |
| ---------------- | ---------------------------------- |
| Git              | Source control and version history |
| GitHub           | Repository hosting                 |
| GitHub Actions   | CI automation                      |
| Python / FastAPI | Demo application                   |
| Docker           | Application containerization       |
| GHCR             | Container image registry           |
| Trivy            | Container vulnerability scanning   |
| Terraform        | Infrastructure as Code             |
| Kubernetes       | Container orchestration            |
| Kind             | Local Kubernetes cluster           |
| Helm             | Kubernetes application packaging   |
| Argo CD          | GitOps continuous delivery         |
| Prometheus       | Metrics collection                 |
| Grafana          | Monitoring and visualization       |

---

# CI/CD and GitOps Workflow

The application repository uses GitHub Actions to automate the CI pipeline.

The pipeline performs:

```text
Code Push
   |
   v
Checkout Source
   |
   v
Install Dependencies
   |
   v
Run Tests
   |
   v
Build Docker Image
   |
   v
Trivy Security Scan
   |
   v
Push Image to GHCR
```

The GitOps repository then contains the Kubernetes deployment configuration.

Argo CD monitors the GitOps repository and synchronizes the desired application state with the Kubernetes cluster.

This creates the following workflow:

```text
Developer
    |
    v
Application Repository
    |
    v
GitHub Actions
    |
    v
Container Image
    |
    v
GHCR
    |
    v
GitOps Repository
    |
    v
Argo CD
    |
    v
Kubernetes
```

---

# Monitoring and Observability

The project also includes Prometheus and Grafana for Kubernetes monitoring.

Prometheus collects metrics from the Kubernetes environment.

Grafana provides dashboards for visualizing metrics.

The monitoring setup includes metrics related to:

* Running Pods
* CPU usage
* Memory usage
* Pod status
* Pod restarts
* Kubernetes cluster resources

Example Prometheus queries used by the project include:

```promql
up
```

and:

```promql
kube_pod_info
```

The monitoring stack is deployed separately from the Terraform-managed resources.

---

# Troubleshooting

## Terraform Cannot Connect to Kubernetes

Check the current context:

```bash
kubectl config current-context
```

Expected:

```text
kind-devops-cluster
```

Then verify the cluster:

```bash
kubectl get nodes
```

If the Kind cluster is not running, start or recreate the required cluster before running Terraform.

---

## Terraform Shows Unexpected Changes

Run:

```bash
terraform plan
```

Carefully inspect the planned changes.

Terraform uses its state and configuration to determine what needs to change.

Avoid running:

```bash
terraform apply
```

without reviewing unexpected changes first.

---

## Pods Are Not Running

Check:

```bash
kubectl get pods -n terraform-demo
```

Then inspect the Pod:

```bash
kubectl describe pod <POD_NAME> -n terraform-demo
```

Also check deployment events:

```bash
kubectl describe deployment terraform-demo -n terraform-demo
```

---

## Service Is Not Working

Check:

```bash
kubectl get service -n terraform-demo
```

Then:

```bash
kubectl get endpoints -n terraform-demo
```

Also verify that the Service selector matches the Pod labels.

The application Pods use:

```text
app: terraform-demo
```

---

## Terraform Configuration Validation Fails

Run:

```bash
terraform fmt
```

followed by:

```bash
terraform validate
```

Terraform will provide the file and line where the configuration problem was detected.

---

# Important Notes

## Local Kind Environment

This project uses a local Kind Kubernetes cluster for development and demonstration.

This avoids requiring a paid cloud Kubernetes environment for the portfolio project.

The Terraform configuration therefore manages Kubernetes resources in the local Kind cluster.

It does not currently provision an AWS EKS cluster or other cloud infrastructure.

---

## Terraform Does Not Manage the Entire Cluster

Terraform only manages the resources defined in the Terraform configuration.

Other components of the project are managed independently.

For example:

```text
Terraform
    |
    +-- terraform-demo namespace
    +-- ConfigMap
    +-- NGINX Deployment
    +-- Service

Argo CD
    |
    +-- Application deployment

Helm
    |
    +-- Application chart

Prometheus/Grafana
    |
    +-- Monitoring stack
```

This separation is intentional.

---

## Production Considerations

For a production implementation, additional practices would normally be considered, including:

* Remote Terraform state
* State locking
* Separate environments
* Secrets management
* Cloud-based Kubernetes
* Private container registries
* Network policies
* RBAC
* Resource quotas
* Terraform modules
* Automated Terraform validation
* Terraform plan checks in CI/CD
* Infrastructure security scanning
* Backup and disaster recovery procedures

These are outside the current scope of this local portfolio implementation.

---

# Summary

This Terraform implementation demonstrates Infrastructure as Code by defining Kubernetes resources declaratively.

The project demonstrates how Terraform can be integrated into a broader DevOps platform alongside:

* GitHub
* GitHub Actions
* Docker
* GHCR
* Trivy
* Kubernetes
* Kind
* Terraform
* Helm
* Argo CD
* Prometheus
* Grafana

The resulting workflow combines:

```text
Infrastructure as Code
        +
Containerization
        +
CI/CD
        +
Security Scanning
        +
Kubernetes
        +
GitOps
        +
Monitoring
```

This provides a complete local DevOps environment that can be reproduced and extended without requiring a paid cloud Kubernetes environment.
