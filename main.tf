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

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 6.0"
  
  name               = "${var.environment}-gitlab"
  vpc_id             = var.vpc_id
  subnets            = var.subnet_ids
  internal           = true
  security_groups    = [module.security_group_alb.security_group_id]
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
      certificate_arn    = data.aws_acm_certificate.this.arn
      port               = 443
      protocol           = "HTTPS"
      target_group_index = 0
    }
  ]

}

module "security_group_alb" {
  source      = "terraform-aws-modules/security-group/aws"
  version     = "~> 4.0"
  
  description         = "Security group for the gitlab ELB"
  name                = "${var.environment}-alb"
  vpc_id              = var.vpc_id
  ingress_cidr_blocks = var.ingress_cidr_blocks
  ingress_rules       = ["https-443-tcp", "ssh-tcp", "openvpn-udp"]
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
  iam_instance_profile        = aws_iam_instance_profile.this.name
  image_id                    = var.ami_id
  instance_type               = var.instance_type
  name_prefix                 = "${var.environment}-gitlab"
  security_groups             = [module.security_group_alb.security_group_id]
  key_name                    = "${var.environment}-gitlab"
  associate_public_ip_address = true
  user_data                   = templatefile("${path.module}/templates/user_data.tpl", 
    {
      docker_compose_yml = base64encode(templatefile("${path.module}/templates/docker-compose.yml.tpl", 
        {
          hostname = "gitlab.${var.domain}"
        })),
      install_script = filebase64("${path.module}/templates/install.sh.tpl")
    }
  )
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.environment}-gitlab"
  role = aws_iam_role.this.name
}

resource "aws_iam_role" "this" {
  name = "${var.environment}-gitlab"
    assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}
