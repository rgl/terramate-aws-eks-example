locals {
  docdb_example_fqdn = "docdb-example.${var.ingress_domain}"
  # see Connecting Programmatically to Amazon DocumentDB at https://docs.aws.amazon.com/documentdb/latest/developerguide/
  docdb_example_master_connection_string = format(
    "mongodb://%s:%s@%s:%d/?tls=true&tlsCAFile=global-bundle.pem&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false",
    urlencode("master"),
    urlencode("Ex0mple!"),
    data.external.docdb_example.result.endpoint,
    27017
  )
}

# see https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external
data "external" "docdb_example" {
  program = ["bash", "${path.module}/docdb-data.sh"]
  query = {
    name = var.cluster_name
  }
}

# TODO re-evaluate replacing aws_acm_certificate/aws_acm_certificate_validation/aws_route53_record
#      with acm-controller et al to be alike the cert-manager/external-dns CRDs
#      when the following issues are addressed.
#      see https://github.com/aws-controllers-k8s/community/issues/1904
#      see https://github.com/aws-controllers-k8s/community/issues/482#issuecomment-755922462
#      see https://github.com/kubernetes-sigs/aws-load-balancer-controller/issues/2509
#      see https://github.com/aws-controllers-k8s/acm-controller/blob/v0.0.14/apis/v1alpha1/certificate.go#L23-L24

# see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate
resource "aws_acm_certificate" "docdb_example" {
  domain_name       = local.docdb_example_fqdn
  validation_method = "DNS"
  key_algorithm     = "EC_prime256v1"
  lifecycle {
    create_before_destroy = true
  }
}

# see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation
resource "aws_acm_certificate_validation" "docdb_example" {
  certificate_arn         = aws_acm_certificate.docdb_example.arn
  validation_record_fqdns = [for record in aws_route53_record.docdb_example_certificate_validation : record.fqdn]
}

# see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record
resource "aws_route53_record" "docdb_example_certificate_validation" {
  for_each = {
    for dvo in aws_acm_certificate.docdb_example.domain_validation_options : dvo.domain_name => {
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

# see https://kubernetes.io/docs/concepts/configuration/
# see https://kubernetes.io/docs/concepts/configuration/secret/
# see https://kubernetes.io/docs/concepts/security/secrets-good-practices/
# see https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret_v1
resource "kubernetes_secret_v1" "docdb_example_master" {
  metadata {
    name = "docdb-example-master"
  }
  data = {
    connection_string = local.docdb_example_master_connection_string
  }
}

# see https://kubernetes.io/docs/concepts/services-networking/ingress/
# see https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#ingress-v1-networking-k8s-io
# see https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.7/guide/ingress/annotations/
# see https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies
# see https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/ingress_v1
resource "kubernetes_ingress_v1" "docdb_example" {
  metadata {
    name = "docdb-example"
    annotations = {
      "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"      = "ip"
      "alb.ingress.kubernetes.io/group.name"       = var.ingress_domain
      "alb.ingress.kubernetes.io/listen-ports"     = "[{\"HTTP\":80},{\"HTTPS\":443}]"
      "alb.ingress.kubernetes.io/ssl-redirect"     = "443"
      "alb.ingress.kubernetes.io/ssl-policy"       = "ELBSecurityPolicy-TLS13-1-2-2021-06"
      "alb.ingress.kubernetes.io/healthcheck-path" = "/health/ready"
    }
  }
  spec {
    rule {
      host = local.docdb_example_fqdn
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "docdb-example"
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
resource "kubernetes_service_v1" "docdb_example" {
  metadata {
    name = "docdb-example"
  }
  spec {
    type = "ClusterIP"
    selector = {
      app = "docdb-example"
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
resource "kubernetes_deployment_v1" "docdb_example" {
  metadata {
    name = "docdb-example"
    labels = {
      app = "docdb-example"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "docdb-example"
      }
    }
    template {
      metadata {
        labels = {
          app = "docdb-example"
        }
      }
      spec {
        enable_service_links = false
        container {
          name  = "docdb-example"
          image = local.docdb_example_image
          env {
            name = "DOCDB_EXAMPLE_CONNECTION_STRING"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.docdb_example_master.metadata[0].name
                key  = "connection_string"
              }
            }
          }
          port {
            name           = "web"
            container_port = 8000
          }
          readiness_probe {
            http_get {
              path = "/health/ready"
              port = "web"
            }
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
      }
    }
  }
}
