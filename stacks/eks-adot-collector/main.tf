locals {
  eks_oidc_issuer_url                = data.aws_eks_cluster.eks.identity[0].oidc[0].issuer
  eks_oidc_provider_arn              = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(local.eks_oidc_issuer_url, "https://", "")}"
  adotcol_namespace                  = "opentelemetry-operator-system"
  adotcol_name                       = "adot"
  adotcol_service_account_name       = "${local.adotcol_name}-collector"
  adotcol_irsa_iam_role_name         = "${data.aws_eks_cluster.eks.name}-${local.adotcol_service_account_name}-irsa"
  adotcol_cloudwatch_log_group_name  = "/aws/eks/${data.aws_eks_cluster.eks.name}/${local.adotcol_name}"
  adotcol_cloudwatch_log_stream_name = local.adotcol_name
  adotcol_tags = {
    Project     = var.project
    Environment = var.environment
    Stack       = var.stack
  }
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_eks_cluster" "eks" {
  name = var.cluster_name
}

# see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group
resource "aws_cloudwatch_log_group" "adotcol" {
  name              = local.adotcol_cloudwatch_log_group_name
  retention_in_days = var.cloudwatch_log_group_retention_in_days
  tags              = local.adotcol_tags
}

# see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_stream
resource "aws_cloudwatch_log_stream" "adotcol" {
  log_group_name = aws_cloudwatch_log_group.adotcol.name
  name           = local.adotcol_cloudwatch_log_stream_name
}

# deploy the adotcol opentelemetrycollector.
# NB the terraform-aws-observability-accelerator uses an helm chart, but that is
#    somewhat complex and cumbersome, so instead, directly create the collector.
#    see https://github.com/aws-ia/terraform-aws-eks-blueprints/tree/v4.32.1/modules/kubernetes-addons/helm-addon
#    see https://github.com/aws-observability/terraform-aws-observability-accelerator/blob/v2.12.1/modules/eks-monitoring/main.tf#L81-L228
# see https://github.com/open-telemetry/opentelemetry-collector
resource "kubernetes_manifest" "adotcol" {
  manifest = {
    apiVersion = "opentelemetry.io/v1alpha1"
    kind       = "OpenTelemetryCollector"
    metadata = {
      namespace = local.adotcol_namespace
      name      = local.adotcol_name
    }
    spec = {
      mode           = "deployment"
      serviceAccount = local.adotcol_service_account_name
      config = yamlencode({
        receivers = {
          otlp = {
            protocols = {
              grpc = {
                endpoint = "0.0.0.0:4317"
              }
            }
          }
        }
        exporters = {
          # see https://github.com/open-telemetry/opentelemetry-collector/blob/main/exporter/logging/README.md
          # NB in recent otelcol the logging exporter was deprecated, and we should
          #    have used the debug exporter, but the adotcol does not yet support
          #    it.
          #    see https://github.com/open-telemetry/opentelemetry-collector/blob/main/exporter/debugexporter/README.md
          logging = {
            verbosity           = "detailed"
            sampling_initial    = 5
            sampling_thereafter = 200
          }
          # see https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/exporter/awscloudwatchlogsexporter
          awscloudwatchlogs = {
            log_group_name  = local.adotcol_cloudwatch_log_group_name
            log_stream_name = local.adotcol_cloudwatch_log_stream_name
          }
        }
        service = {
          pipelines = {
            logs = {
              receivers  = ["otlp"]
              processors = []
              exporters  = ["logging", "awscloudwatchlogs"]
            }
          }
        }
      })
    }
  }
}

# see https://github.com/aws-ia/terraform-aws-eks-blueprints/tree/v4.32.1/modules/irsa
module "adotcol_irsa" {
  source                            = "github.com/aws-ia/terraform-aws-eks-blueprints//modules/irsa?ref=v4.32.1"
  create_kubernetes_namespace       = false
  kubernetes_namespace              = local.adotcol_namespace
  create_kubernetes_service_account = true
  kubernetes_service_account        = local.adotcol_service_account_name
  eks_cluster_id                    = data.aws_eks_cluster.eks.name
  eks_oidc_provider_arn             = local.eks_oidc_provider_arn
  irsa_iam_role_name                = local.adotcol_irsa_iam_role_name
  irsa_iam_policies = [
    # logs.
    aws_iam_policy.adotcol.arn,
  ]
  tags = local.adotcol_tags
}

# see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy
resource "aws_iam_policy" "adotcol" {
  name   = local.adotcol_irsa_iam_role_name
  policy = data.aws_iam_policy_document.adotcol.json
}

# see https://aws-otel.github.io/docs/getting-started/adot-eks-add-on/config-container-logs
# see CloudWatch Logs permissions reference at https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/permissions-reference-cwl.html
# see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document
# NB we didn't use CloudWatchAgentServerPolicy because it has more permissions
#    than required.
#    see https://docs.aws.amazon.com/aws-managed-policy/latest/reference/CloudWatchAgentServerPolicy.html
data "aws_iam_policy_document" "adotcol" {
  statement {
    sid    = "WriteLogs"
    effect = "Allow"
    resources = [
      aws_cloudwatch_log_stream.adotcol.arn,
    ]
    actions = [
      "logs:PutLogEvents",
    ]
  }
}
