output "region" {
  value = var.region
}

output "cluster_name" {
  value = var.cluster_name
}

output "cluster_oidc_issuer_url" {
  # e.g. https://oidc.eks.eu-west-1.amazonaws.com/id/DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD
  value = local.eks_oidc_issuer_url
}

output "cluster_oidc_configuration_url" {
  # e.g. https://oidc.eks.eu-west-1.amazonaws.com/id/DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD/.well-known/openid-configuration
  value = "${local.eks_oidc_issuer_url}/.well-known/openid-configuration"
}
