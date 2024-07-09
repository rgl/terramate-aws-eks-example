locals {
  otel_example_fqdn = "otel-example.${var.ingress_domain}"
}

# TODO re-evaluate replacing aws_acm_certificate/aws_acm_certificate_validation/aws_route53_record
#      with acm-controller et al to be alike the cert-manager/external-dns CRDs
#      when the following issues are addressed.
#      see https://github.com/aws-controllers-k8s/community/issues/1904
#      see https://github.com/aws-controllers-k8s/community/issues/482#issuecomment-755922462
#      see https://github.com/kubernetes-sigs/aws-load-balancer-controller/issues/2509
#      see https://github.com/aws-controllers-k8s/acm-controller/blob/v0.0.14/apis/v1alpha1/certificate.go#L23-L24

# see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate
resource "aws_acm_certificate" "otel_example" {
  domain_name       = local.otel_example_fqdn
  validation_method = "DNS"
  key_algorithm     = "EC_prime256v1"
  lifecycle {
    create_before_destroy = true
  }
}

# see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation
resource "aws_acm_certificate_validation" "otel_example" {
  certificate_arn         = aws_acm_certificate.otel_example.arn
  validation_record_fqdns = [for record in aws_route53_record.otel_example_certificate_validation : record.fqdn]
}

# see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record
resource "aws_route53_record" "otel_example_certificate_validation" {
  for_each = {
    for dvo in aws_acm_certificate.otel_example.domain_validation_options : dvo.domain_name => {
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

# see https://kubernetes.io/docs/concepts/services-networking/ingress/
# see https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#ingress-v1-networking-k8s-io
# see https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.7/guide/ingress/annotations/
# see https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies
# see https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/ingress_v1
resource "kubernetes_ingress_v1" "otel_example" {
  metadata {
    name = "otel-example"
    annotations = {
      "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"      = "ip"
      "alb.ingress.kubernetes.io/group.name"       = var.ingress_domain
      "alb.ingress.kubernetes.io/listen-ports"     = "[{\"HTTP\":80},{\"HTTPS\":443}]"
      "alb.ingress.kubernetes.io/ssl-redirect"     = "443"
      "alb.ingress.kubernetes.io/ssl-policy"       = "ELBSecurityPolicy-TLS13-1-2-2021-06"
      "alb.ingress.kubernetes.io/healthcheck-path" = "/healthz/ready"
    }
  }
  spec {
    rule {
      host = local.otel_example_fqdn
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "otel-example"
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

# see https://kubernetes.io/docs/concepts/services-networking/service/#clusterip
# see https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#service-v1-core
# see https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#serviceport-v1-core
# see https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_v1
resource "kubernetes_service_v1" "otel_example" {
  metadata {
    name = "otel-example"
  }
  spec {
    type = "ClusterIP"
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
# see https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#probe-v1-core
# see https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#httpgetaction-v1-core
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
          env {
            name  = "QUOTES_BASE_URL"
            value = "https://${local.otel_example_fqdn}"
          }
          port {
            name           = "web"
            container_port = 8000
          }
          readiness_probe {
            http_get {
              path = "/healthz/ready"
              port = "web"
            }
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
