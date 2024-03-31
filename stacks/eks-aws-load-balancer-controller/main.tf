locals {
  eks_oidc_issuer_url   = data.aws_eks_cluster.eks.identity[0].oidc[0].issuer
  eks_oidc_provider_arn = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(local.eks_oidc_issuer_url, "https://", "")}"
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_eks_cluster" "eks" {
  name = var.cluster_name
}

# see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone
resource "aws_route53_zone" "ingress" {
  name          = var.ingress_domain
  force_destroy = true
}

# see https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.7/
# see https://github.com/kubernetes-sigs/aws-load-balancer-controller/tree/v2.7.1/helm/aws-load-balancer-controller/Chart.yaml
# see https://github.com/kubernetes-sigs/aws-load-balancer-controller/tree/v2.7.1/helm/aws-load-balancer-controller/values.yaml
# see https://github.com/kubernetes-sigs/aws-load-balancer-controller/tree/v2.7.1/helm/aws-load-balancer-controller
# see https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/tag/v2.7.1
# see https://github.com/kubernetes-sigs/aws-load-balancer-controller/
# see https://github.com/aws-ia/terraform-aws-eks-blueprints-addons/releases/tag/v1.16.2
# see https://github.com/aws-ia/terraform-aws-eks-blueprints-addons
module "aws_load_balancer_controller" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.16.2"

  cluster_name      = data.aws_eks_cluster.eks.name
  cluster_endpoint  = data.aws_eks_cluster.eks.endpoint
  cluster_version   = var.cluster_version
  oidc_provider_arn = local.eks_oidc_provider_arn

  enable_aws_load_balancer_controller = true

  aws_load_balancer_controller = {
    wait                 = true
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

# see https://github.com/kubernetes-sigs/external-dns/tree/v0.14.0/charts/external-dns/Chart.yaml
# see https://github.com/kubernetes-sigs/external-dns/tree/v0.14.0/charts/external-dns/values.yaml
# see https://kubernetes-sigs.github.io/external-dns/
# see https://github.com/aws-ia/terraform-aws-eks-blueprints-addons/releases/tag/v1.16.2
# see https://github.com/aws-ia/terraform-aws-eks-blueprints-addons
module "external_dns" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.16.2"

  cluster_name      = data.aws_eks_cluster.eks.name
  cluster_endpoint  = data.aws_eks_cluster.eks.endpoint
  cluster_version   = var.cluster_version
  oidc_provider_arn = local.eks_oidc_provider_arn

  enable_external_dns = true

  external_dns_route53_zone_arns = [
    aws_route53_zone.ingress.arn,
  ]

  external_dns = {
    wait = true
  }

  depends_on = [
    module.aws_load_balancer_controller,
  ]
}
