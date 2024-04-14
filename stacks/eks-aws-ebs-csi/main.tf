locals {
  eks_oidc_issuer_url   = data.aws_eks_cluster.eks.identity[0].oidc[0].issuer
  eks_oidc_provider_arn = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(local.eks_oidc_issuer_url, "https://", "")}"
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_eks_cluster" "eks" {
  name = var.cluster_name
}

# see https://docs.aws.amazon.com/eks/latest/userguide/eks-add-ons.html
# see https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html
# see https://github.com/kubernetes-sigs/aws-ebs-csi-driver
# see https://github.com/aws-ia/terraform-aws-eks-blueprints-addons/releases/tag/v1.16.2
# see https://github.com/aws-ia/terraform-aws-eks-blueprints-addons
module "aws_ebs_csi" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.16.2"

  cluster_name      = data.aws_eks_cluster.eks.name
  cluster_endpoint  = data.aws_eks_cluster.eks.endpoint
  cluster_version   = var.cluster_version
  oidc_provider_arn = local.eks_oidc_provider_arn

  eks_addons = {
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.aws_ebs_csi_irsa.iam_role_arn
    }
  }
}

# see https://registry.terraform.io/modules/terraform-aws-modules/iam/aws/latest/submodules/iam-role-for-service-accounts-eks
# see https://registry.terraform.io/modules/terraform-aws-modules/iam/aws/latest
module "aws_ebs_csi_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.39.0"

  role_name_prefix = "${data.aws_eks_cluster.eks.name}-ebs-csi-"

  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = local.eks_oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}
