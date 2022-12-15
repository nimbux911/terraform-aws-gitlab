output "gitlab_instance_id" {
  value = aws_instance.this.id
}

output "gitlab_volume_id" {
  value = var.gitlab_snapshot_id != null ? aws_ebs_volume.gitlab_snapshot[0].id : aws_ebs_volume.gitlab.id
}