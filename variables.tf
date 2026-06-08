variable "environment" {
  default = "test"
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
  type        = string
  default     = "route53"
}

variable "cloudflare_api_token_ssm_parameter_name" {
  type        = string
  default     = null
}
