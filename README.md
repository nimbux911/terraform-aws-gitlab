# AWS Gitlab Terraform Module

Terraform module which runs gitlan on a single EC2 instance on AWS.

## Current version

Running this example creates a running instance of Gitlab with the following characteristics:
   
   - Docker, docker-compose and certbot are installed during the deployment.
   - Certbot uses the dns-route53 plugin to create the certificate for the required domain. 
   - Gitlab is running on a single EC2 instance on AWS.
   - Automated backups using AWS Backup
   - Automated restore from snapshot
   - Automated certificate renew through certbot
   
   Note: if you are testing the module and you use the same domain name (ex: gitlab.example.com) more than 5 times during a short term, certbot will fail and won't let you create/update certificates using the same domain name. There is a workaround in the [Letscenrypt Documentation](https://letsencrypt.org/docs/duplicate-certificate-limit/)
   
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
    ingress_cidr_blocks = ["192.168.0.0/24"]
    zone_id             = "Z05149662IBDII4KPR8MQ"
    certbot_email       = "john.doe@example.com"
    host_domain         = "gitlab.example.com"
    gitlab_volume_size  = 30
    backups_enabled     = true
    retention_days      = 7
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment name of the resources. | `string` | `test` | no |
| host\_domain | The domain that will be used to reach the gitlab page. | `string` | ` ` | yes |
| vpc\_id | ID of the VPC which the subnet belongs. | `string` | ` ` | yes |
| subnet\_id | Subnet id where to place the EC2 instance. | `string` | ` ` | yes |
| instance\_type | EC2 instance type. | `string` | `t3.micro` | no |
| ingress\_cidr\_blocks | List of IPv4 CIDR ranges to use on all ingress rules. | `list[string]` | `[]` | yes |
| zone\_id | Zone ID of the Route53 where the record will be created. | `string` | `""` | yes |
| certbot\_email | E-mail where certbot will send notifications about the certificate. | `string` | `""` | yes |
| gitlab\_volume\_size | Size in gb of the gitlab volume | `number` | `20` | no |
| backups\_enabled | Enabled or not the automated backups | `bool` | `false` | no |
| retention\_days | Retention in days for automated backups | `number` | `null` | no | 
| gitlab\_snapshot\_id | Snapshot id to use for restoring an existitent Gitlab | `string` | `null` | no |
