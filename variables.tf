variable "environment" {
  default = "test"
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
  type      = string
  default   = null
  sensitive = true
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
  type      = string
  default   = null
  sensitive = true
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
