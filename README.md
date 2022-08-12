# AWS Gitlab Terraform Module

Terraform module which runs gitlan on a single EC2 instance on AWS.

## Current version

Running this example creates a running instance of Gitlab with the following characteristics:
   
   - Docker, docker-compose and certbot are installed during the deployment.
   - Certbot uses the dns-route53 plugin to create the certificate for the required domain. 
   - Gitlab is running on a single EC2 instance on AWS. To enter over ssh use port 2222.
   
   Note: if you are testing the module and you use the same domain name (ex: gitlab.example.com) more than 5 times during a short term, certbot will fail and won't let you create/update certificates using the same domain name. Try another one if this happens (ex: gitlab1.example.com)
   
Future additions:

    - Create ASG
    - Create runners
    
## Usage

## Gitlab Service

```hcl
module private_gitlab {
    source = "github.com/nimbux911/terraform-aws-gitlab.git?ref=N911-9555"
    environment = "ops"
    domain = "gitlab.example.com"
    vpc_id = "vpc-1234567"
    subnet_ids = ["subnet-01a3f5a6b3231570f", "subnet-03310ccc0e2c89072", "subnet-02acbaf7116d9c1a9"]
    ami_id = "ami-052efd3df9dad4825"
    instance_type = "t3a.medium"
    ingress_cidr_blocks = ["0.0.0.0/0"]
    zone_id = "Z05149662IBDII4KPR8MQ"
    email = "john.doe@example.com"
    swap_volume_size = "8"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment name of the resources. | `string` | `""` | yes |
| domain | The name that will be used to reach the gitlab page. | `string` | `""` | yes |
| vpc\_id | VPC ID where OpenVPN will be deployed. | `string` | `""` | yes |
| subnet\_ids | Public subnet ids from the designed VPC. | `list[string]` | `[]` | yes |
| ami\_id | AMI ID to user for the OpenVPN EC2 instance. | `string` | `""` | yes |
| instance\_type | OpenVPN EC2 instance type. | `string` | `""` | yes |
| ingress_cidr_blocks | List of IPv4 CIDR ranges to use on all ingress rules. | `list[string]` | `[]` | yes |
| zone_id | Zone ID of the Route53 where the record will be created. | `string` | `""` | yes |
| email | E-mail where certbot will send notifications about the certificate. | `string` | `""` | yes |
| swap_volume_size | Size in gb of the swap volume | `string` | `""` | yes |
