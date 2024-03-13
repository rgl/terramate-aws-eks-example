locals {
  adot_addon_context = {
    aws_caller_identity_account_id = data.aws_caller_identity.current.account_id
    aws_caller_identity_arn        = data.aws_caller_identity.current.arn
    aws_partition_id               = data.aws_partition.current.partition
    aws_region_name                = var.region
    aws_eks_cluster_endpoint       = data.aws_eks_cluster.eks.endpoint
    eks_cluster_id                 = data.aws_eks_cluster.eks.name
    eks_oidc_issuer_url            = data.aws_eks_cluster.eks.identity[0].oidc[0].issuer
    eks_oidc_provider_arn          = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://", "")}"
    irsa_iam_role_path             = "/"
    irsa_iam_permissions_boundary  = null
    tags = {
      Project     = var.project
      Environment = var.environment
      Stack       = var.stack
    }
  }
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_eks_cluster" "eks" {
  name = var.cluster_name
}

# see https://github.com/aws-observability/terraform-aws-observability-accelerator/tree/v2.12.1/modules/eks-monitoring/add-ons/adot-operator
# see https://github.com/aws-ia/terraform-aws-eks-blueprints/tree/v4.32.1/modules/kubernetes-addons/cert-manager
# see https://github.com/open-telemetry/opentelemetry-operator
# see https://github.com/open-telemetry/opentelemetry-collector
# see https://github.com/aws-observability/terraform-aws-observability-accelerator/issues/247
module "adot_operator" {
  source              = "github.com/aws-observability/terraform-aws-observability-accelerator//modules/eks-monitoring/add-ons/adot-operator?ref=v2.12.1"
  kubernetes_version  = data.aws_eks_cluster.eks.version
  enable_cert_manager = true
  addon_context       = local.adot_addon_context
}
