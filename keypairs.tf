resource "tls_private_key" "this" {
  count = var.gitlab_key_pair == {} ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_ssm_parameter" "public_key" {
  count = var.gitlab_key_pair == {} ? 1 : 0

  name  = "${var.environment}-gitlab-public-ssh-key"
  type  = "SecureString"
  value = base64encode(tls_private_key.this[0].public_key_openssh)
}

resource "aws_ssm_parameter" "private_key" {
  count = var.gitlab_key_pair == {} ? 1 : 0

  name  = "${var.environment}-gitlab-private-ssh-key"
  type  = "SecureString"
  tier  = "Advanced"
  value = base64encode(tls_private_key.this[0].private_key_pem)
}

resource "aws_key_pair" "this" {
  count = var.gitlab_key_pair == {} ? 1 : 0

  key_name   = "${var.environment}-gitlab"
  public_key = base64decode(aws_ssm_parameter.public_key[0].value)
}
