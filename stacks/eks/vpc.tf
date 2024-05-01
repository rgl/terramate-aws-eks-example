locals {
  azs              = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnets   = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 3, k + 0 * length(local.azs))]
  private_subnets  = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 3, k + 1 * length(local.azs))]
  database_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 3, k + 2 * length(local.azs))]
}

data "aws_availability_zones" "available" {
  state = "available"
}

# the kubernetes cluster vpc.
# see https://docs.aws.amazon.com/eks/latest/userguide/creating-a-vpc.html
# see https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html
# see https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws
# see https://github.com/terraform-aws-modules/terraform-aws-vpc
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = var.cluster_name

  azs              = local.azs
  cidr             = var.vpc_cidr
  public_subnets   = local.public_subnets
  private_subnets  = local.private_subnets
  database_subnets = local.database_subnets

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}
