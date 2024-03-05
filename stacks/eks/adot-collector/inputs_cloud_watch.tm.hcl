generate_hcl "_inputs_cloud_watch.auto.tfvars" {
  content {
    cloudwatch_log_group_retention_in_days = global.cluster_cloudwatch_log_group_retention_in_days
  }
}
