# terraform-aws-gitlab

## Gitlab Service

```hcl
module private_gitlab {
    source = ""github.com/nimbux911/terraform-aws-gitlab.git?ref="N911-9555"
    environment = var.environment
    route53_zone_name = data.terraform_remote_state.route53.outputs.route53_zone_name
    route53_zone_zone_id = data.terraform_remote_state.route53.outputs.route53_zone_zone_id
    domain = var.domain
    vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
    private_subnets_ids = data.terraform_remote_state.vpc.outputs.private_subnets_ids
    subnet_ids = data.terraform_remote_state.vpc.outputs.public_subnets_ids
    ami_id = var.ami_id
    instance_type = var.instance_type
    docker_cidr = var.docker_cidr
    project = var.project
}
```
