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
  value = aws_ebs_volume.gitlab.id
}


#aws_backup_vault.gitlab[0]
#aws_ebs_volume.gitlab
#aws_ebs_volume.gitlab_snapshot[0]
#aws_iam_instance_profile.this
#aws_iam_role.this
#aws_iam_role_policy.certbot_r53
#aws_iam_role_policy.gitlab_backup[0]
#aws_instance.this
#aws_key_pair.this
#aws_launch_template.gitlab
#aws_route53_record.this
#aws_ssm_parameter.private_key
#aws_ssm_parameter.public_key
#aws_volume_attachment.gitlab
#tls_private_key.this
#module.security_group_gitlab.aws_security_group.this_name_prefix[0]
#module.security_group_gitlab.aws_security_group_rule.egress_rules[0]
#module.security_group_gitlab.aws_security_group_rule.ingress_rules[0]
#module.security_group_gitlab.aws_security_group_rule.ingress_rules[1]
#module.security_group_gitlab.aws_security_group_rule.ingress_with_cidr_blocks[0]
