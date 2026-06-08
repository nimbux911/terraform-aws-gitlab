terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
    }

    aws = {
      source = "hashicorp/aws"
    }

    tls = {
      source = "hashicorp/tls"
    }
  }
}
