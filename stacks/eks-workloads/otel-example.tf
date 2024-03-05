# see https://kubernetes.io/docs/concepts/services-networking/service/#clusterip
# see https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#service-v1-core
# see https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#serviceport-v1-core
# see https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_v1
resource "kubernetes_service_v1" "otel_example" {
  metadata {
    name = "otel-example"
  }
  spec {
    type = "LoadBalancer"
    selector = {
      app = "otel-example"
    }
    port {
      name        = "web"
      port        = 80
      protocol    = "TCP"
      target_port = "web"
    }
  }
}

# see https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
# see https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#deployment-v1-apps
# see https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#podtemplatespec-v1-core
# see https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#container-v1-core
# see https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment_v1
resource "kubernetes_deployment_v1" "otel_example" {
  metadata {
    name = "otel-example"
    labels = {
      app = "otel-example"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "otel-example"
      }
    }
    template {
      metadata {
        labels = {
          app = "otel-example"
        }
      }
      spec {
        enable_service_links = false
        container {
          name  = "otel-example"
          image = local.otel_example_image
          env {
            name  = "OTEL_EXPORTER_OTLP_ENDPOINT"
            value = local.otel_exporter_otlp_endpoint
          }
          env {
            name  = "OTEL_EXPORTER_OTLP_PROTOCOL"
            value = local.otel_exporter_otlp_protocol
          }
          env {
            name  = "ASPNETCORE_URLS"
            value = "http://+:8000"
          }
          port {
            name           = "web"
            container_port = 8000
          }
          resources {
            requests = {
              cpu    = "0.2"
              memory = "64Mi"
            }
            limits = {
              cpu    = "0.2"
              memory = "64Mi"
            }
          }
        }
      }
    }
  }
}
