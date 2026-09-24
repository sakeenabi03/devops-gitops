terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_namespace" "terraform_demo" {
  metadata {
    name = var.namespace_name
  }
}

resource "kubernetes_config_map" "app_config" {
  metadata {
    name      = var.config_map_name
    namespace = kubernetes_namespace.terraform_demo.metadata[0].name
  }

  data = {
    APP_NAME    = "devops-demo"
    ENVIRONMENT = "local"
    MANAGED_BY  = "terraform"
  }
}

resource "kubernetes_deployment" "terraform_demo" {
  metadata {
    name      = var.app_name
    namespace = kubernetes_namespace.terraform_demo.metadata[0].name
  }

  spec {
    replicas = var.replica_count

    selector {
      match_labels = {
        app = "terraform-demo"
      }
    }

    template {
      metadata {
        labels = {
          app = "terraform-demo"
        }
      }

      spec {
        container {
          name  = "nginx"
          image = var.container_image

          port {
            container_port = 80
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 80
            }

            initial_delay_seconds = 5
            period_seconds        = 10
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 80
            }

            initial_delay_seconds = 10
            period_seconds        = 20
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "64Mi"
            }

            limits = {
              cpu    = "250m"
              memory = "128Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "terraform_demo" {
  metadata {
    name      = var.app_name
    namespace = kubernetes_namespace.terraform_demo.metadata[0].name
  }

  spec {
    selector = {
      app = "terraform-demo"
    }

    port {
      port        = 80
      target_port = 80
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}