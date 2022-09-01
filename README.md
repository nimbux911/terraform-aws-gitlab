# AWS Gitlab Terraform Module

Terraform module which runs gitlab on a single EC2 instance on AWS.

## Current version

Running this example creates a running instance of Gitlab with the following characteristics:
   
   - Docker, docker-compose and certbot are installed during the deployment.
   - Certbot uses the dns-route53 plugin to create the certificate for the required domain. 
   - Gitlab is running on a single EC2 instance on AWS. To enter over ssh use port 2222.
   - Backup configuration provided in order to take a snapshot of the instance.
   
   Note: if you are testing the module and you use the same domain name (ex: gitlab.example.com) more than 5 times during a short term, certbot will fail and won't let you create/update certificates using the same domain name. Try another one if this happens (ex: gitlab1.example.com)
   
Future additions:

    - Create ASG
    - Create runners
    
## Usage

## Gitlab Service

```hcl
module private_gitlab {
    source = "github.com/nimbux911/terraform-aws-gitlab.git?ref=v1.0.0"
    environment = "ops"
    vpc_id = "vpc-1234567"
    private_subnet_ids = ["subnet-01a3f5a6b3231570f", "subnet-03310ccc0e2c89072", "subnet-02acbaf7116d9c1a9"]
    ami_id = "ami-052efd3df9dad4825"
    instance_type = "t3a.medium"
    ingress_cidr_blocks = ["0.0.0.0/0"]
    zone_id = "Z05149662IBDII4KPR8MQ"
    email = "john.doe@example.com"
    dns = "testgitlab.example.com"
    swap_volume_size = "8"
    configure_backups                      = true
    backup_schedule_frequency              = "cron(00 21 ? * MON-FRI *)"
    backup_plan_name                       = "test-backup-plan"
    backup_plan_rule_name                  = "test-every-24-hours-1-day-retention"
    backup_plan_resources_selection_name   = "test-server-resources"
    backup_plan_role_name                  = "ExampleAWSBackupServiceRole"
    backup_plan_selection_key              = "Backup"
    backup_plan_selection_value            = "true"
    backup_retention_days                  = 1
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment name of the resources. | `string` | `""` | yes |
| dns | The name that will be used to reach the gitlab page. | `string` | `""` | yes |
| vpc\_id | VPC ID where OpenVPN will be deployed. | `string` | `""` | yes |
| subnet\_ids | Public subnet ids from the designed VPC. | `list[string]` | `[]` | yes |
| ami\_id | AMI ID to user for the OpenVPN EC2 instance. | `string` | `""` | yes |
| instance\_type | OpenVPN EC2 instance type. | `string` | `""` | yes |
| ingress_cidr_blocks | List of IPv4 CIDR ranges to use on all ingress rules. | `list[string]` | `[]` | yes |
| zone_id | Zone ID of the Route53 where the record will be created. | `string` | `""` | yes |
| email | E-mail where certbot will send notifications about the certificate. | `string` | `""` | yes |
| swap_volume_size | Size in gb of the swap volume | `string` | `""` | yes |
| configure_backups | Tell the module if you want to take a backup or not of the instance. Default: false | `bool` | `false` | yes |
| backup_schedule_frequency | Frequency of the backup to be taken | `string` | `""` | yes |
| backup_plan_name | Name of the backup | `string` | `""` | yes |
| backup_plan_rule_name | A display name for a backup rule | `string` | `""` | yes |
| backup_plan_resources_selection_name | The display name of a resource selection document | `string` | `""` | yes |
| backup_plan_role_name | The name that will be used by the backup role | `string` | `""` | yes |
| backup_plan_selection_key | The key in a key-value pair | `string` | `""` | yes |
| backup_plan_selection_value | The value in a key-value pair | `string` | `""` | yes |
| backup_retention_days | How many days will be the snapshot retained | `string` | `""` | yes |