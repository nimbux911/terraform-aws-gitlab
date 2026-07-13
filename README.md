# AWS Gitlab Terraform Module

Terraform module which runs Gitlab on a single EC2 instance on AWS.

## Current version

Running this example creates a running instance of Gitlab with the following characteristics:
   
   - Docker, docker-compose and certbot are installed during the deployment.
   - Certbot uses the dns-route53 plugin to create the certificate for the required domain. 
   - Gitlab is running on a single EC2 instance on AWS.
   - Automated backups using AWS Backup
   - Automated restore from snapshot
   - Automated certificate renewal through certbot
   
   Note: if you are testing the module and you use the same domain name (ex: gitlab.example.com) more than 5 times during a short term, certbot will fail and won't let you create/update certificates using the same domain name. There is a workaround in the [Letsencrypt Documentation](https://letsencrypt.org/docs/duplicate-certificate-limit/)
   
Future additions:

    - Create ASG
    - Create runners
    
## Usage

## Gitlab Service

```hcl
module private_gitlab {
    source             = "git::https://github.com/nimbux911/terraform-aws-gitlab.git?ref=v1.0.0"
    environment         = "ops"
    vpc_id              = "vpc-1234567"
    subnet_id           = "subnet-01a3f5a6b3231570f"
    instance_type       = "t3a.medium"
    ingress_cidr_blocks  = ["192.168.0.0/24"]
    custom_ingress_rules = [
        {
            from_port   = 443
            to_port     = 443
            protocol    = "tcp"
            cidr_blocks = "172.17.0.0/16"
            description = "Dev VPC"
        },
        {
            from_port   = 443
            to_port     = 443
            protocol    = "tcp"
            cidr_blocks = "172.19.0.0/16"
            description = "Stg VPC"
        },
        {
            from_port   = 443
            to_port     = 443
            protocol    = "tcp"
            cidr_blocks = "172.21.0.0/16"
            description = "Prd VPC"
        }
    ]
    zone_id             = "Z05149662IBDII4KPR8MQ"
    certbot_email       = "john.doe@example.com"
    host_domain            = "gitlab.example.com"
    gitlab_volume_size     = 30
    backups_enabled        = true
    backup_cron_expression = "0 21 * * *"
    retention_days         = 7
    swap_volume_size       = 8
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment name of the resources. | `string` | `test` | no |
| stack\_name | Name assigned to the Gitlab stack resources. | `string` | `gitlab` | no |
| public\_ssh\_key\_ssm\_parameter\_name | SSM SecureString parameter name used to store the generated public SSH key. | `string` | `gitlab-public-ssh-key` | no |
| private\_ssh\_key\_ssm\_parameter\_name | SSM SecureString parameter name used to store the generated private SSH key. | `string` | `gitlab-private-ssh-key` | no |
| host\_domain | The domain that will be used to reach the gitlab page. | `string` | ` ` | yes |
| vpc\_id | ID of the VPC which the subnet belongs. | `string` | ` ` | yes |
| subnet\_id | Subnet id where to place the EC2 instance. | `string` | ` ` | yes |
| instance\_type | EC2 instance type. | `string` | `t3.micro` | no |
| ingress\_cidr\_blocks | List of IPv4 CIDR ranges to use on all ingress rules. | `list[string]` | ` ` | yes |
| custom\_ingress\_rules | Custom inbound CIDR rules to add to the GitLab security group. See [Custom Ingress Rules](#custom-ingress-rules). | `list(object)` | `[]` | no |
| zone_id | DNS zone ID. Use the Route 53 hosted zone ID when `dns_provider = "route53"`, or the Cloudflare zone ID when `dns_provider = "cloudflare"`. | `string` | ` ` | yes |
| certbot\_email | E-mail where certbot will send notifications about the certificate. | `string` | ` ` | yes |
| gitlab\_volume\_size | Size in gb of the gitlab volume | `number` | `20` | no |
| backups\_enabled | Enabled or not the automated backups | `bool` | `false` | no |
| backup\_cron\_expression | Cron expression used to schedule GitLab backups on the instance. | `string` | `0 6 * * *` | no |
| retention\_days | Retention in days for automated backups | `number` | `null` | no | 
| gitlab\_snapshot\_id | Snapshot id to use for restoring an existitent Gitlab | `string` | `null` | no |
| swap\_volume\_size | Size in gb of the swap volume | `number` | `8` | no |
| dns_provider | DNS provider used for DNS records and certbot validation. Supported values: `route53`, `cloudflare`. | `string` | `route53` | no |
| cloudflare_api_token_ssm_parameter_name | Name/path of an existing SSM SecureString parameter containing the Cloudflare API token for certbot. Required when `dns_provider = "cloudflare"`. | `string` | `null` | no |
| smtp_enabled | Enable SMTP settings for GitLab email delivery. | `bool` | `false` | no |
| smtp_address | SMTP server address. | `string` | `null` | no |
| smtp_port | SMTP server port. | `number` | `587` | no |
| smtp_user_name | SMTP username. | `string` | `null` | no |
| smtp_password | SMTP password. | `string` | `null` | no |
| smtp_authentication | SMTP authentication method. | `string` | `login` | no |
| smtp_domain | SMTP HELO domain. | `string` | `null` | no |
| smtp_enable_starttls_auto | Enable STARTTLS automatically for SMTP. | `bool` | `true` | no |
| gitlab_email_from | GitLab sender email address. | `string` | `null` | no |
| gitlab_email_reply_to | GitLab reply-to email address. | `string` | `null` | no |
| bitbucket_omniauth_enabled | Enable Bitbucket OmniAuth provider for GitLab. | `bool` | `false` | no |
| bitbucket_app_id | Bitbucket OAuth app key. | `string` | `null` | no |
| bitbucket_app_secret | Bitbucket OAuth app secret. | `string` | `null` | no |
| bitbucket_url | Bitbucket URL used by the OmniAuth provider. | `string` | `https://bitbucket.org/` | no |
| bitbucket_sign_in_enabled | Show Bitbucket as a GitLab sign-in provider. Disable when using Bitbucket only for imports. | `bool` | `true` | no |
| bitbucket_import_enabled | Allow Bitbucket Cloud as a GitLab import source. | `bool` | `false` | no |
| docker\_bridge\_cidr | CIDR used by Docker's default bridge. Must not overlap with any VPC, peered VPC, VPN, or on-prem network. | `string` | `10.200.0.1/24` | no |
| docker\_default\_address\_pool\_base | Base CIDR for Docker-created bridge networks. Must not overlap with any routed network. | `string` | `10.200.0.0/16` | no |
| docker\_default\_address\_pool\_size | Prefix size Docker uses when allocating networks from docker_default_address_pool_base. | `number` | `24` | no |

## Outputs

| Name | Description |
|------|-------------|
| security\_group\_id | Gitlab's security group ID. |
| gitlab\_instance\_id | Gitlab's EC2 instance ID. |
| launch\_template\_id | Gitlab's launch template ID. |
| gitlab\_volume\_id | Gitlab's EBS volume ID. |

## Custom Ingress Rules

Use `custom_ingress_rules` to add one or more custom inbound CIDR rules to the GitLab security group.

Each rule supports:

| Name | Type | Required |
|------|------|:--------:|
| from_port | `number` | yes |
| to_port | `number` | yes |
| protocol | `string` | yes |
| cidr_blocks | `string` | yes |
| description | `string` | no |

Example:

```hcl
custom_ingress_rules = [
  {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = "172.17.0.0/16"
  }
]
```

## DNS Provider

By default, this module uses Route 53 for DNS records and certbot DNS validation.

```hcl
dns_provider = "route53"
zone_id      = "Z05149662IBDII4KPR8MQ"
```

To use Cloudflare instead, set:

```hcl
dns_provider = "cloudflare"
zone_id      = "023e105f4ecef8ad9ca31a8372d0c353"
cloudflare_api_token_ssm_parameter_name = "/gitlab/cloudflare/api-token"
```

The SSM parameter must already exist before the instance boots. Here must be stored the Cloudflare api token, which will be used by Certbot.

## SMTP

Set `smtp_enabled = true` to configure GitLab email delivery through an external SMTP server.

```hcl
smtp_enabled              = true
smtp_address              = "smtp.example.com"
smtp_port                 = 587
smtp_user_name            = "gitlab@example.com"
smtp_password             = "smtp-password"
smtp_authentication       = "login"
smtp_domain               = "example.com"
smtp_enable_starttls_auto = true
gitlab_email_from         = "gitlab@example.com"
gitlab_email_reply_to     = "noreply@example.com"
```

## Bitbucket

Set `bitbucket_omniauth_enabled = true` to enable Bitbucket OAuth sign-in for GitLab.

```hcl
bitbucket_omniauth_enabled = true
bitbucket_app_id           = "bitbucket-oauth-key"
bitbucket_app_secret       = "bitbucket-oauth-secret"
bitbucket_url              = "https://bitbucket.org/"
```

To allow Bitbucket Cloud project imports, enable:

```hcl
bitbucket_import_enabled = true
```

If you only want Bitbucket imports and do not want Bitbucket shown as a sign-in provider, set:

```hcl
bitbucket_sign_in_enabled = false
```
