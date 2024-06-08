locals {
  kubernetes_hello_fqdn = "kubernetes-hello.${var.ingress_domain}"
}

# TODO re-evaluate replacing aws_acm_certificate/aws_acm_certificate_validation/aws_route53_record
#      with acm-controller et al to be alike the cert-manager/external-dns CRDs
#      when the following issues are addressed.
#      see https://github.com/aws-controllers-k8s/community/issues/1904
#      see https://github.com/aws-controllers-k8s/community/issues/482#issuecomment-755922462
#      see https://github.com/kubernetes-sigs/aws-load-balancer-controller/issues/2509
#      see https://github.com/aws-controllers-k8s/acm-controller/blob/v0.0.14/apis/v1alpha1/certificate.go#L23-L24

# see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate
resource "aws_acm_certificate" "kubernetes_hello" {
  domain_name       = local.kubernetes_hello_fqdn
  validation_method = "DNS"
  key_algorithm     = "EC_prime256v1"
  lifecycle {
    create_before_destroy = true
  }
}

# see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation
resource "aws_acm_certificate_validation" "kubernetes_hello" {
  certificate_arn         = aws_acm_certificate.kubernetes_hello.arn
  validation_record_fqdns = [for record in aws_route53_record.kubernetes_hello_certificate_validation : record.fqdn]
}

# see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record
resource "aws_route53_record" "kubernetes_hello_certificate_validation" {
  for_each = {
    for dvo in aws_acm_certificate.kubernetes_hello.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  allow_overwrite = true
  type            = each.value.type
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  zone_id         = data.aws_route53_zone.ingress.zone_id
}

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

# see https://kubernetes.io/docs/concepts/services-networking/ingress/
# see https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#ingress-v1-networking-k8s-io
# see https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.7/guide/ingress/annotations/
# see https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies
# see https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/ingress_v1
resource "kubernetes_ingress_v1" "kubernetes_hello" {
  metadata {
    name = "kubernetes-hello"
    annotations = {
      "alb.ingress.kubernetes.io/scheme"       = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"  = "ip"
      "alb.ingress.kubernetes.io/group.name"   = var.ingress_domain
      "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTP\":80},{\"HTTPS\":443}]"
      "alb.ingress.kubernetes.io/ssl-redirect" = "443"
      "alb.ingress.kubernetes.io/ssl-policy"   = "ELBSecurityPolicy-TLS13-1-2-2021-06"
    }
  }
  spec {
    rule {
      host = local.kubernetes_hello_fqdn
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "kubernetes-hello"
              port {
                name = "web"
              }
            }
          }
        }
      }
    }
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
    type = "ClusterIP"
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
# see https://kubernetes.io/docs/concepts/storage/projected-volumes/#serviceaccounttoken
# see https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/
# see https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#deployment-v1-apps
# see https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#podtemplatespec-v1-core
# see https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#container-v1-core
# see https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#serviceaccounttokenprojection-v1-core
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
          # configure the go runtime to honour the k8s memory and cpu
          # resource limits.
          # NB resourceFieldRef will cast the limits to bytes and integer
          #    number of cpus (rounding up to the nearest integer).
          # see https://pkg.go.dev/runtime
          # see https://www.riverphillips.dev/blog/go-cfs/
          # see https://github.com/golang/go/issues/33803
          # see https://github.com/traefik/traefik-helm-chart/pull/1029
          env {
            name = "GOMEMLIMIT"
            value_from {
              resource_field_ref {
                resource = "limits.memory"
              }
            }
          }
          env {
            name = "GOMAXPROCS"
            value_from {
              resource_field_ref {
                resource = "limits.cpu"
              }
            }
          }
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
            name       = "tokens"
            read_only  = true
            mount_path = "/var/run/secrets/tokens"
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
          name = "tokens"
          projected {
            sources {
              # NB the kubelet will periodically rotate this token.
              # NB the token is rotated when its older than 80% of its time
              #    to live or if the token is older than 24h.
              # NB in production, set to a higher value (e.g. 3600 (1h)).
              # NB the minimum allowed value is 600 (10m).
              # NB this is equivalent of using the TokenRequest API.
              #    see https://kubernetes.io/docs/reference/kubernetes-api/authentication-resources/token-request-v1/
              # NB this is equivalent of executing:
              #       kubectl create token kubernetes-hello --audience example.com --duration 600s
              #    see https://kubernetes.io/docs/reference/kubectl/generated/kubectl_create/kubectl_create_token/
              service_account_token {
                path               = "example.com-jwt.txt"
                audience           = "https://example.com"
                expiration_seconds = 600
              }
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
