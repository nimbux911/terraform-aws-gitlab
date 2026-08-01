variable "environment" {
  default = "test"
}

variable "enable_monitoring" {
  description = "Enable CloudWatch Agent host metrics and GitLab health and certificate custom metrics through SSM."
  type        = bool
  default     = false
}

variable "gitlab_healthcheck_url" {
  description = "Internal GitLab health endpoint checked from the GitLab instance."
  type        = string
  default     = null
}

variable "gitlab_metrics_namespace" {
  description = "CloudWatch namespace used for GitLab custom metrics."
  type        = string
  default     = "Custom/GitLab"
}

variable "gitlab_cert_host" {
  description = "Host whose served TLS certificate is checked from the GitLab instance."
  type        = string
  default     = null
}

variable "gitlab_cert_port" {
  description = "TLS port used by the GitLab certificate check."
  type        = number
  default     = 443
}

variable "stack_name" {
  type    = string
  default = "gitlab"
}

variable "public_ssh_key_ssm_parameter_name" {
  type    = string
  default = "gitlab-public-ssh-key"
}

variable "private_ssh_key_ssm_parameter_name" {
  type    = string
  default = "gitlab-private-ssh-key"
}

variable "subnet_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "ingress_cidr_blocks" {
  type = list(string)
}

variable "custom_ingress_rules" {
  description = "Custom inbound CIDR rules to add to the GitLab security group."
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = string
    description = optional(string)
  }))
  default = []
}

variable "zone_id" {
  type = string
}

variable "certbot_email" {
  type = string
}

variable "gitlab_volume_size" {
  type    = number
  default = 20
}

variable "host_domain" {
  type = string
}

variable "backups_enabled" {
  type    = bool
  default = false
}

variable "retention_days" {
  type    = number
  default = null
}

variable "backup_cron_expression" {
  description = "Cron expression used to schedule GitLab backups on the instance."
  type        = string
  default     = "0 6 * * *"
}

variable "backup_replication_enabled" {
  description = "Enable cross-account and cross-region replication of unencrypted GitLab EBS backup snapshots."
  type        = bool
  default     = false

  validation {
    condition     = !var.backup_replication_enabled || var.backups_enabled
    error_message = "backup_replication_enabled requires backups_enabled to be true."
  }
}

variable "backup_replication_cron_expression" {
  description = "Cron expression used to schedule GitLab backup replication on the instance."
  type        = string
  default     = "15 6 * * *"
}

variable "backup_replication_destination_account_id" {
  description = "AWS account ID that will own the replicated EBS snapshots."
  type        = string
  default     = null

  validation {
    condition     = !var.backup_replication_enabled || (var.backup_replication_destination_account_id != null && can(regex("^[0-9]{12}$", var.backup_replication_destination_account_id)))
    error_message = "backup_replication_destination_account_id must be a 12-digit AWS account ID when replication is enabled."
  }
}

variable "backup_replication_destination_region" {
  description = "AWS region where the destination account will copy the EBS snapshots."
  type        = string
  default     = null

  validation {
    condition     = !var.backup_replication_enabled || (var.backup_replication_destination_region != null && trimspace(var.backup_replication_destination_region) != "")
    error_message = "backup_replication_destination_region must be set when replication is enabled."
  }
}

variable "backup_replication_destination_role_arn" {
  description = "IAM role ARN assumed in the destination account to copy EBS snapshots."
  type        = string
  default     = null

  validation {
    condition = !var.backup_replication_enabled || (
      var.backup_replication_destination_role_arn != null &&
      var.backup_replication_destination_account_id != null &&
      can(regex("^arn:[^:]+:iam::${var.backup_replication_destination_account_id}:role/.+$", var.backup_replication_destination_role_arn))
    )
    error_message = "backup_replication_destination_role_arn must be a role in the destination account when replication is enabled."
  }
}

variable "backup_replication_poll_interval_seconds" {
  description = "Seconds between backup recovery point and EBS snapshot status checks."
  type        = number
  default     = 30

  validation {
    condition     = var.backup_replication_poll_interval_seconds > 0
    error_message = "backup_replication_poll_interval_seconds must be greater than zero."
  }
}

variable "backup_replication_timeout_seconds" {
  description = "Maximum seconds to wait for a current recovery point and destination snapshot copy."
  type        = number
  default     = 43200

  validation {
    condition     = var.backup_replication_timeout_seconds > var.backup_replication_poll_interval_seconds
    error_message = "backup_replication_timeout_seconds must be greater than backup_replication_poll_interval_seconds."
  }
}

variable "gitlab_snapshot_id" {
  type    = string
  default = null
}

variable "swap_volume_size" {
  type    = number
  default = 8
}

variable "gitlab_container_name" {
  type    = string
  default = "gitlab"
}

variable "enable_s3_artifacts" {
  type    = bool
  default = false
}

variable "bucket_name" {
  type    = string
  default = null
}

variable "dns_provider" {
  type    = string
  default = "route53"
}

variable "cloudflare_api_token_ssm_parameter_name" {
  type    = string
  default = null
}

variable "smtp_enabled" {
  type    = bool
  default = false
}

variable "smtp_address" {
  type    = string
  default = null
}

variable "smtp_port" {
  type    = number
  default = 587
}

variable "smtp_user_name" {
  type    = string
  default = null
}

variable "smtp_password" {
  type    = string
  default = null
}

variable "smtp_authentication" {
  type    = string
  default = "login"
}

variable "smtp_domain" {
  type    = string
  default = null
}

variable "smtp_enable_starttls_auto" {
  type    = bool
  default = true
}

variable "gitlab_email_from" {
  type    = string
  default = null
}

variable "gitlab_email_reply_to" {
  type    = string
  default = null
}

variable "bitbucket_omniauth_enabled" {
  type    = bool
  default = false
}

variable "bitbucket_app_id" {
  type    = string
  default = null
}

variable "bitbucket_app_secret" {
  type    = string
  default = null
}

variable "bitbucket_url" {
  type    = string
  default = "https://bitbucket.org/"
}

variable "bitbucket_sign_in_enabled" {
  description = "Whether Bitbucket should appear as a sign-in provider. Disable this if you only want import support."
  type        = bool
  default     = true
}

variable "bitbucket_import_enabled" {
  description = "Whether GitLab should allow Bitbucket Cloud as an import source."
  type        = bool
  default     = false
}

variable "docker_bridge_cidr" {
  description = "CIDR used by Docker's default bridge. Must not overlap with any VPC, peered VPC, VPN, or on-prem network."
  type        = string
  default     = "10.200.0.1/24"
}

variable "docker_default_address_pool_base" {
  description = "Base CIDR for Docker-created bridge networks. Must not overlap with any routed network."
  type        = string
  default     = "10.200.0.0/16"
}

variable "docker_default_address_pool_size" {
  description = "Prefix size Docker uses when allocating networks from docker_default_address_pool_base."
  type        = number
  default     = 24
}
