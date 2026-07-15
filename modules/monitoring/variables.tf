variable "instance_id" {
  type = string
}

variable "role_name" {
  type = string
}

variable "region" {
  type = string
}

variable "environment" {
  type = string
}

variable "healthcheck_url" {
  type = string
}

variable "metrics_namespace" {
  type = string
}

variable "cert_host" {
  type = string
}

variable "cert_port" {
  type = number
}
