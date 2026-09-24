output "namespace" {
  description = "Kubernetes namespace managed by Terraform"
  value       = kubernetes_namespace.terraform_demo.metadata[0].name
}

output "application_name" {
  description = "Name of the Terraform-managed application"
  value       = kubernetes_deployment.terraform_demo.metadata[0].name
}

output "container_image" {
  description = "Container image used by the application"
  value       = var.container_image
}

output "replica_count" {
  description = "Number of application replicas"
  value       = var.replica_count
}

output "service_name" {
  description = "Kubernetes service managed by Terraform"
  value       = kubernetes_service.terraform_demo.metadata[0].name
}