locals {
  eks_oidc_issuer_url   = data.aws_eks_cluster.eks.identity[0].oidc[0].issuer
  eks_oidc_provider_arn = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(local.eks_oidc_issuer_url, "https://", "")}"
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_eks_cluster" "eks" {
  name = var.cluster_name
}

# see https://github.com/open-telemetry/opentelemetry-operator
# see https://github.com/open-telemetry/opentelemetry-collector
# see https://github.com/aws-observability/terraform-aws-observability-accelerator/issues/247
# see https://github.com/aws-ia/terraform-aws-eks-blueprints-addons/releases/tag/v1.16.1
# see https://github.com/aws-ia/terraform-aws-eks-blueprints-addons
module "adot_operator" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.16.1"

  cluster_name      = data.aws_eks_cluster.eks.name
  cluster_endpoint  = data.aws_eks_cluster.eks.endpoint
  cluster_version   = var.cluster_version
  oidc_provider_arn = local.eks_oidc_provider_arn

  enable_cert_manager = true

  cert_manager = {
    role_name            = "${data.aws_eks_cluster.eks.name}-cert-manager-irsa"
    role_name_use_prefix = false
    wait                 = true
  }

  eks_addons = {
    adot = {
      most_recent = true
    }
  }
}
