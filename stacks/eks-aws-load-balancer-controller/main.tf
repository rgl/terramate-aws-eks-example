locals {
  eks_oidc_issuer_url   = data.aws_eks_cluster.eks.identity[0].oidc[0].issuer
  eks_oidc_provider_arn = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(local.eks_oidc_issuer_url, "https://", "")}"
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_eks_cluster" "eks" {
  name = var.cluster_name
}

# see https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.7/
# see https://github.com/kubernetes-sigs/aws-load-balancer-controller/tree/v2.7.1/helm/aws-load-balancer-controller/Chart.yaml
# see https://github.com/kubernetes-sigs/aws-load-balancer-controller/tree/v2.7.1/helm/aws-load-balancer-controller/values.yaml
# see https://github.com/kubernetes-sigs/aws-load-balancer-controller/tree/v2.7.1/helm/aws-load-balancer-controller
# see https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/tag/v2.7.1
# see https://github.com/kubernetes-sigs/aws-load-balancer-controller/
# see https://github.com/aws-ia/terraform-aws-eks-blueprints-addons/releases/tag/v1.16.0
# see https://github.com/aws-ia/terraform-aws-eks-blueprints-addons
module "aws_load_balancer_controller" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.16.0"

  cluster_name      = data.aws_eks_cluster.eks.name
  cluster_endpoint  = data.aws_eks_cluster.eks.endpoint
  cluster_version   = var.cluster_version
  oidc_provider_arn = local.eks_oidc_provider_arn

  enable_aws_load_balancer_controller = true

  aws_load_balancer_controller = {
    role_name            = "${data.aws_eks_cluster.eks.name}-aws-load-balancer-controller-irsa"
    role_name_use_prefix = false
    values = [jsonencode({
      replicaCount = 1,
      ingressClassConfig = {
        default = true
      }
    })]
  }
}
