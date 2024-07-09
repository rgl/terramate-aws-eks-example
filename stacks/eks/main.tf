# the kubernetes cluster.
# see https://registry.terraform.io/modules/terraform-aws-modules/eks/aws
# see https://github.com/terraform-aws-modules/terraform-aws-eks
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.17.2"

  cluster_name                   = var.cluster_name
  cluster_version                = var.cluster_version
  cluster_endpoint_public_access = true

  cluster_addons = {
    # see https://docs.aws.amazon.com/eks/latest/userguide/managing-vpc-cni.html
    # see https://docs.aws.amazon.com/eks/latest/userguide/eks-add-ons.html
    # see https://github.com/aws/amazon-vpc-cni-k8s
    vpc-cni = {
      before_compute = true
      most_recent    = true
      configuration_values = jsonencode({
        env = {
          ENABLE_POD_ENI                    = "true"
          ENABLE_PREFIX_DELEGATION          = "true"
          POD_SECURITY_GROUP_ENFORCING_MODE = "standard"
        }
        enableNetworkPolicy = "true"
      })
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  create_cluster_security_group = false
  create_node_security_group    = false

  authentication_mode = "API"

  enable_cluster_creator_admin_permissions = true

  cloudwatch_log_group_retention_in_days = var.cluster_cloudwatch_log_group_retention_in_days

  eks_managed_node_groups = {
    default = {
      # use the bottlerocket os.
      # see https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-ami-bottlerocket.html
      # see https://docs.aws.amazon.com/eks/latest/userguide/update-managed-node-group.html
      # see https://github.com/terraform-aws-modules/terraform-aws-eks/blob/v20.17.2/modules/eks-managed-node-group/main.tf#L351
      ami_type = "BOTTLEROCKET_x86_64"

      instance_types = ["m5.large"]

      desired_size = 1
      min_size     = 1
      max_size     = 3

      update_config = {
        max_unavailable_percentage = 50
      }
    }
  }
}
