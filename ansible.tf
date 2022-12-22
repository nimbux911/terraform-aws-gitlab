locals {
  gitlab_version     = var.gitlab_version == null ? "latest" : var.gitlab_version
  hostname           = var.domain
  email              = var.email
  dns                = var.domain
  json_max_file      = var.json_max_file == "" ? "" : var.json_max_file
  
  gitlab_rb_default = tolist(["external_url 'https://{{ hostname }}'",
                              "letsencrypt['enable'] = false",
                              "nginx['ssl_certificate'] = '/etc/gitlab/ssl/{{ hostname }}.crt'",
                              "nginx['ssl_certificate_key'] = '/etc/gitlab/ssl/{{ hostname }}.key'"
                             ])


  gitlab_extraconf = flatten([ for option_name, option_value in var.gitlab_rb_extra_conf : [
                                 for key, value in option_value:
                                   "${option_name}['${key}'] = ${value}"
                               ]
                             ])

  gitlab_rb_merged = concat(local.gitlab_rb_default, local.gitlab_extraconf )

  gitlab_rb_merged_stringed = join("\",\"", local.gitlab_rb_merged )
}

resource "local_file" "ansible_extra_vars" {
  filename = "${path.module}/resources/ansible/extra_vars.yml"
  content =<<-EOF
hostname : ${local.hostname}
gitlab_version : ${local.gitlab_version}
email : ${local.email}
dns : ${local.dns}
json_max_file : ${local.json_max_file}
extra_conf : ["${local.gitlab_rb_merged_stringed}"] 
EOF
}

resource "local_file" "get_priv_key" {
  content = base64decode(data.aws_ssm_parameter.key_pair[0].value)
  filename = "${path.module}/resources/ansible/gitlab_priv_key"
  file_permission = "0600"
}

data "template_file" "ansible_inventory_template" {
  template = file("${path.module}/resources/templates/inventory.tpl")
  vars = {
    hostname = var.domain
    pvt_key = "${path.module}/resources/ansible/gitlab_priv_key"
  }
}

resource "local_file" "ansible_inventory" {
  content = data.template_file.ansible_inventory_template.rendered
  filename = "${path.module}/resources/ansible/inventory.yml"
}

resource "null_resource" "ansible" {
  depends_on = [ aws_instance.this, local_file.get_priv_key, local_file.ansible_inventory, local_file.ansible_extra_vars ]

  connection {
    timeout     = "180s"
    type        = "ssh"
    port        = "2222"
    user        = "ubuntu"
    private_key = base64decode(data.aws_ssm_parameter.key_pair[0].value)
    host        = var.domain
  }

  # This remote-exec is to wait for ssh on 2222 to be available
  provisioner "remote-exec" {
    inline = ["uname -n"]
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ${path.module}/resources/ansible/inventory.yml -e @${path.module}/resources/ansible/extra_vars.yml ${path.module}/resources/ansible/gitlab_setup.yml"

  }
}
