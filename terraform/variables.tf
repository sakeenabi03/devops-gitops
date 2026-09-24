variable "namespace_name" {
  description = "Kubernetes namespace for the Terraform demo"
  type        = string
  default     = "terraform-demo"
}

variable "app_name" {
  description = "Name of the Terraform-managed application"
  type        = string
  default     = "terraform-demo"
}

variable "config_map_name" {
  description = "Name of the application ConfigMap"
  type        = string
  default     = "devops-demo-config"
}

variable "replica_count" {
  description = "Number of application replicas"
  type        = number
  default     = 2
}

variable "container_image" {
  description = "Container image for the application"
  type        = string
  default     = "nginx:1.27"
}