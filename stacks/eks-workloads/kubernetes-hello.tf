# see https://kubernetes.io/docs/reference/access-authn-authz/rbac/
# see https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#role-v1-rbac-authorization-k8s-io
# see https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role_v1
resource "kubernetes_role_v1" "pod_read" {
  metadata {
    name = "pod-read"
  }
  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["get", "list"]
  }
}

# see https://kubernetes.io/docs/reference/access-authn-authz/rbac/
# see https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#rolebinding-v1-rbac-authorization-k8s-io
# see https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role_binding_v1
resource "kubernetes_role_binding_v1" "kubernetes_hello_pod_read" {
  metadata {
    namespace = "default"
    name      = "kubernetes-hello-pod-read"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role_v1.pod_read.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    namespace = kubernetes_service_account_v1.kubernetes_hello.metadata[0].namespace
    name      = kubernetes_service_account_v1.kubernetes_hello.metadata[0].name
  }
}

# see https://kubernetes.io/docs/concepts/security/service-accounts/
# see https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/
# see https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#serviceaccount-v1-core
# see https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account_v1
resource "kubernetes_service_account_v1" "kubernetes_hello" {
  metadata {
    namespace = "default"
    name      = "kubernetes-hello"
  }
}

# see https://kubernetes.io/docs/concepts/configuration/
# see https://kubernetes.io/docs/concepts/configuration/secret/
# see https://kubernetes.io/docs/concepts/security/secrets-good-practices/
# see https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret_v1
resource "kubernetes_secret_v1" "kubernetes_hello" {
  metadata {
    namespace = "default"
    name      = "kubernetes-hello"
  }
  data = {
    username = "ali.baba"
    password = "Open Sesame"
  }
}

# see https://kubernetes.io/docs/concepts/configuration/
# see https://kubernetes.io/docs/concepts/configuration/configmap/
# see https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/
# see https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#configmap-v1-core
# see https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map_v1
resource "kubernetes_config_map_v1" "kubernetes_hello" {
  metadata {
    namespace = "default"
    name      = "kubernetes-hello"
  }
  data = {
    "config-a.toml" = <<-EOF
      # a comment
      [table1]
      name = "config-a"

      [table2]
      key = "string value"
      EOF
    "config-b.toml" = <<-EOF
      # a comment
      [table1]
      name = "config-b"

      [table2]
      key = "string value"
      EOF
  }
}

# see https://kubernetes.io/docs/concepts/services-networking/service/
# see https://kubernetes.io/docs/concepts/services-networking/service/#clusterip
# see https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#service-v1-core
# see https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#serviceport-v1-core
# see https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_v1
resource "kubernetes_service_v1" "kubernetes_hello" {
  metadata {
    name = "kubernetes-hello"
  }
  spec {
    type = "LoadBalancer"
    selector = {
      app = "kubernetes-hello"
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
resource "kubernetes_deployment_v1" "kubernetes_hello" {
  metadata {
    name = "kubernetes-hello"
    labels = {
      app = "kubernetes-hello"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "kubernetes-hello"
      }
    }
    template {
      metadata {
        labels = {
          app = "kubernetes-hello"
        }
      }
      spec {
        service_account_name = kubernetes_service_account_v1.kubernetes_hello.metadata[0].name
        enable_service_links = false
        container {
          name  = "kubernetes-hello"
          image = local.kubernetes_hello_image
          # see https://github.com/kubernetes/kubernetes/blob/master/test/e2e/common/downward_api.go
          env {
            name = "POD_UID"
            value_from {
              field_ref {
                field_path = "metadata.uid"
              }
            }
          }
          env {
            name = "POD_NAME"
            value_from {
              field_ref {
                field_path = "metadata.name"
              }
            }
          }
          env {
            name = "POD_NAMESPACE"
            value_from {
              field_ref {
                field_path = "metadata.namespace"
              }
            }
          }
          volume_mount {
            name       = "secrets"
            read_only  = true
            mount_path = "/var/run/secrets/example"
          }
          volume_mount {
            name       = "configs"
            read_only  = true
            mount_path = "/var/run/configs/example"
          }
          port {
            name           = "web"
            container_port = 8000
          }
          resources {
            requests = {
              cpu    = "0.1"
              memory = "24Mi"
            }
            limits = {
              cpu    = "0.1"
              memory = "24Mi"
            }
          }
        }
        volume {
          name = "secrets"
          secret {
            secret_name  = kubernetes_secret_v1.kubernetes_hello.metadata[0].name
            default_mode = "0400"
          }
        }
        volume {
          name = "configs"
          config_map {
            name         = kubernetes_config_map_v1.kubernetes_hello.metadata[0].name
            default_mode = "0400"
          }
        }
      }
    }
  }
}