output "ingress_domain" {
  value = var.ingress_domain
}

output "ingress_domain_name_servers" {
  value = aws_route53_zone.ingress.name_servers
}
