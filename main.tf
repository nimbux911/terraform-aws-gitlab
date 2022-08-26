resource "aws_route53_record" "this" {
  zone_id = var.zone_id
  name    = var.domain
  type    = "A"
  ttl     = "300"
  records = [aws_instance.this.private_ip]
}

output "security_group_id" {
  value       = aws_security_group.gitlab.id
}

output "priv_key" {
  value  = local_file.get_priv_key.content
}

resource "aws_instance" "this" {
  iam_instance_profile        = aws_iam_instance_profile.this.name
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.private_subnet_ids[0]
  vpc_security_group_ids      = [ aws_security_group.gitlab.id ]
  key_name                    = var.gitlab_key_pair == {} ? "${var.environment}-gitlab" : var.gitlab_key_pair.key_pair_name
  associate_public_ip_address = false

  root_block_device {
    volume_size = var.volume_size == null ? null : var.volume_size
  }

  user_data                   = file("${path.module}/resources/scripts/install.sh")

  lifecycle {
    create_before_destroy = true
  }

  tags                        = {
    Name = "${var.environment}-gitlab"
  }
}

resource "aws_ebs_volume" "swap" {
  availability_zone = data.aws_availability_zones.available.names[0]
  size              = var.swap_volume_size
}

resource "aws_volume_attachment" "swap" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.swap.id
  instance_id = aws_instance.this.id
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

resource "aws_iam_role_policy" "this" {
  name   = "${var.environment}-gitlab"
  role   = aws_iam_role.this.id
  policy = <<-EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "route53:ListHostedZones",
                "route53:GetChange"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Effect" : "Allow",
            "Action" : [
                "route53:ChangeResourceRecordSets"
            ],
            "Resource" : [
                "arn:aws:route53:::hostedzone/${var.zone_id}"
            ]
        }
    ]
}
  EOF
}
