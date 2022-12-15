output "gitlab_instance_id" {
  value = aws_instance.this.id
}

output "launch_template_id" {
  value = aws_launch_template.gitlab.id
}

output "gitlab_volume_id" {
  value = var.gitlab_snapshot_id != null ? aws_ebs_volume.gitlab_snapshot[0].id : aws_ebs_volume.gitlab.id
}

output "keypair_name" {
  value = aws_key_pair.this.key_name
}

output "ssm_private_key_name" {
  value = aws_ssm_parameter.private_key.name
}