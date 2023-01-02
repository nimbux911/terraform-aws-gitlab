output "security_group_id" {
  value = module.security_group_test_gitlab.security_group_id
}

output "test_gitlab_instance_id" {
  value = aws_instance.this.id
}

output "launch_template_id" {
  value = aws_launch_template.test_gitlab.id
}

output "test_gitlab_volume_id" {
  value = var.test_gitlab_snapshot_id != null ? aws_ebs_volume.test_gitlab_snapshot[0].id : aws_ebs_volume.test_gitlab.id
}
