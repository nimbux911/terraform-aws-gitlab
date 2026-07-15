output "metrics_namespace" {
  value = var.metrics_namespace
}

output "health_check_metric_name" {
  value = "GitLabHealthCheckSuccess"
}

output "certificate_expiry_metric_name" {
  value = "GitLabCertDaysRemaining"
}
