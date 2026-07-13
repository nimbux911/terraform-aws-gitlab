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

variable "backup_cron_expression" {
  description = "Cron expression used to schedule GitLab backups on the instance."
  type        = string
  default     = "0 6 * * *"
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
