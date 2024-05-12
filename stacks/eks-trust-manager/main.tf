# see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster
data "aws_eks_cluster" "eks" {
  name = var.cluster_name
}

# install trust-manager.
# see https://cert-manager.io/docs/tutorials/getting-started-with-trust-manager/
# see https://github.com/cert-manager/trust-manager
# see https://github.com/golang/go/blob/go1.22.3/src/crypto/x509/root_linux.go
# see https://artifacthub.io/packages/helm/cert-manager/trust-manager
# see https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release
resource "helm_release" "trust_manager" {
  namespace  = "cert-manager"
  name       = "trust-manager"
  repository = "https://charts.jetstack.io"
  chart      = "trust-manager"
  version    = "0.9.2"
  values = [yamlencode({
    secretTargets = {
      enabled              = true
      authorizedSecretsAll = true
    }
  })]
}

# install reloader.
# NB tls libraries typically load the certificates from ca-certificates.crt
#    file once, when they are started, and they never reload the file again.
#    reloader will automatically restart them when their configmap/secret
#    changes.
# see https://cert-manager.io/docs/tutorials/getting-started-with-trust-manager/
# see https://github.com/stakater/reloader
# see https://artifacthub.io/packages/helm/stakater/reloader
# see https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release
resource "helm_release" "reloader" {
  namespace  = "kube-system"
  name       = "reloader"
  repository = "https://stakater.github.io/stakater-charts"
  chart      = "reloader"
  version    = "1.0.95"
  values = [yamlencode({
    reloader = {
      autoReloadAll = true
    }
  })]
}
