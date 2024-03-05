output "kubernetes_region" {
  value = var.region
}

output "kubernetes_cluster_name" {
  value = module.eks.cluster_name
}

output "kubernetes_oidc_issuer_url" {
  # e.g. https://oidc.eks.eu-west-1.amazonaws.com/id/DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD
  value = module.eks.cluster_oidc_issuer_url
}

output "kubernetes_oidc_configuration_url" {
  # e.g. https://oidc.eks.eu-west-1.amazonaws.com/id/DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD/.well-known/openid-configuration
  value = "${module.eks.cluster_oidc_issuer_url}/.well-known/openid-configuration"
}
