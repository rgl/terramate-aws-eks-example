data "aws_caller_identity" "current" {}

data "aws_eks_cluster" "eks" {
  name = var.cluster_name
}

locals {
  otel_exporter_otlp_endpoint = "http://adot-collector.opentelemetry-operator-system.svc.cluster.local:4317"
  otel_exporter_otlp_protocol = "grpc"
  eks_oidc_issuer_url         = data.aws_eks_cluster.eks.identity[0].oidc[0].issuer
  ecr_domain                  = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com"
  images = {
    for key, value in var.source_images : key => "${local.ecr_domain}/${var.cluster_name}/${key}:${value.tag}"
  }
  otel_example_image     = local.images.otel-example
  kubernetes_hello_image = local.images.kubernetes-hello
}
