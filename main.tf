data "aws_availability_zones" "available" {
}

data "aws_region" "current" {}

resource "aws_route53_zone" "this" {
  name         = "gitlab.ops.alaskaops.io"

}

resource "aws_key_pair" "this" {
  key_name   = "${var.environment}-gitlab"
  public_key = base64decode(aws_ssm_parameter.public_key.value)
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_ssm_parameter" "public_key" {
  name  = "${var.environment}-gitlab-public-ssh-key"
  type  = "SecureString"
  value = base64encode(tls_private_key.this.public_key_openssh)
}

resource "aws_ssm_parameter" "private_key" {
  name  = "${var.environment}-gitlab-private-ssh-key"
  type  = "SecureString"
  tier  = "Advanced"
  value = base64encode(tls_private_key.this.private_key_pem)
}  

module "gitlab_cert" {
  source         = "terraform-aws-modules/acm/aws"
  version        = "~> v3.5.0"
  
  domain_name    = var.route53_zone_name[var.domain]
  zone_id        = var.route53_zone_zone_id[var.domain]

  subject_alternative_names = [ 
    var.route53_zone_name[var.domain],
    "*.${var.route53_zone_name[var.domain]}",
  ]
}

module "alb_gitlab_private" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 6.0"
  
  name               = "${var.environment}-gitlab"
  vpc_id             = var.vpc_id
  subnets            = var.private_subnets_ids
  internal           = true
  security_groups    = [module.security_group_gitlab_alb.security_group_id]
  load_balancer_type = "application"
  enable_cross_zone_load_balancing = true

  target_groups = [
    {
      name             = "${var.environment}-gitlab"
      backend_protocol = "HTTP"
      backend_port     = 32080
      target_type      = "instance"
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
        protocol            = "HTTP"
        matcher             = "200,404"
      }
    }
  ]

  https_listeners = [
    {
      certificate_arn    = module.gitlab_cert.acm_certificate_arn
      port               = 443
      protocol           = "HTTPS"
      target_group_index = 0
    }
  ]

}

module "security_group_gitlab_alb" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"
  description = "Security group for the gitlab ELB"
  name        = "${var.environment}-alb"
  vpc_id      = var.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["https-443-tcp", "ssh-tcp", "openvpn-udp", "all-icmp"]
  egress_rules        = ["all-all"]
}

resource "aws_autoscaling_group" "this" {
  desired_capacity     = 1
  launch_configuration = aws_launch_configuration.this.id
  max_size             = 1
  min_size             = 1
  name                 = "${var.environment}-gitlab"
  vpc_zone_identifier  = [var.subnet_ids[0]]
  health_check_type    = "EC2"
  tag {
    key                 = "Name"
    value               = "${var.environment}-gitlab"
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "this" {
  image_id                    = var.ami_id
  instance_type               = var.instance_type
  name_prefix                 = "${var.environment}-gitlab"
  security_groups             = [module.security_group_gitlab_alb.security_group_id]
  key_name                    = "${var.environment}-gitlab"
  associate_public_ip_address = true
  user_data                   = templatefile("${path.module}/templates/user_data.tpl", 
      {
        aws_region        = data.aws_region.current.name,
        s3_bucket         = aws_s3_bucket.gitlab.bucket,
        docker_cidr       = var.docker_cidr
      }
    )
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_s3_bucket" "gitlab" {
  bucket = "${var.environment}-${var.project}-gitlab"
}

resource "aws_s3_bucket_acl" "gitlab" {
  bucket = aws_s3_bucket.gitlab.id
  acl    = "private"
}

resource "aws_s3_object" "docker_compose" {
  bucket = aws_s3_bucket.gitlab.bucket
  key    = "docker-compose.yml"
  source = "${path.module}/templates/docker-compose.yml.tpl"
}