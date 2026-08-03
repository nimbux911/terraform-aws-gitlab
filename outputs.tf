output "security_group_id" {
  value = module.security_group_gitlab.security_group_id
}

output "gitlab_instance_id" {
  value = aws_instance.this.id
}

output "launch_template_id" {
  value = aws_launch_template.gitlab.id
}

output "gitlab_volume_id" {
  value = local.gitlab_volume_id
}

output "gitlab_metrics_namespace" {
  value       = var.enable_monitoring ? module.monitoring[0].metrics_namespace : null
  description = "CloudWatch namespace used for GitLab custom metrics when monitoring is enabled."
}

output "gitlab_health_check_metric_name" {
  value       = var.enable_monitoring ? module.monitoring[0].health_check_metric_name : null
  description = "CloudWatch custom metric published by the internal GitLab health check."
}

output "gitlab_certificate_expiry_metric_name" {
  value       = var.enable_monitoring ? module.monitoring[0].certificate_expiry_metric_name : null
  description = "CloudWatch custom metric published by the GitLab TLS certificate check."
}
