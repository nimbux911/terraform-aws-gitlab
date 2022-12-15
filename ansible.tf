locals {
  gitlab_version     = var.gitlab_version == null ? "latest" : var.gitlab_version
  hostname           = var.domain
  email              = var.email
  dns                = var.domain
  db_host            = var.external_db.db_host
  db_password        = var.external_db.db_password
  smtp_address       = var.gitlab_conf_smtp.smtp_address
  smtp_port          = var.gitlab_conf_smtp.smtp_port
  

  gitlab_rb_default = list( "external_url 'https://{{ hostname }}'",
                             "letsencrypt['enable'] = false",
                             "nginx['ssl_certificate'] = '/etc/gitlab/ssl/{{ hostname }}.crt'",
                             "nginx['ssl_certificate_key'] = '/etc/gitlab/ssl/{{ hostname }}.key'"
                           )

  gitlab_rb_external_db = var.external_db.db_host == "" ? list( "" ) : list( "postgresql['enable'] = false",
                            "gitlab_rails['db_adapter'] = 'postgresql'",
                            "gitlab_rails['db_encoding'] = 'unicode'",
                            "gitlab_rails['db_host'] = '{{ db_host }}'",
                            "gitlab_rails['db_password'] = '{{ db_password }}'"
                          )

  gitlab_rb_smtp = var.gitlab_conf_smtp.smtp_address == "" ? list("") : list( "gitlab_rails['smtp_address'] = '{{ smtp_address }}',
                     "gitlab_rails['smtp_port'] = '{{ smtp_port }}'
                   )

  # We merge all parameters to be passed to the env vat GITLAB_OMNIBUS_CONFIG
  gitlab_rb_merged = concat(local.gitlab_rb_default, local.gitlab_rb_external_db, gitlab_rb_smtp)

  # And we conver that to a big string
  gitlab_rb_merged_stringed = join("\",\"", local.gitlab_rb_merged )
}


resource "local_file" "ansible_extra_vars" {
  filename = "${path.module}/resources/ansible/extra_vars.yml"
  content =<<-EOF
hostname : ${local.hostname}
gitlab_version : ${local.gitlab_version}
email : ${local.email}
dns : ${var.domain}
db_host : ${local.db_host}
db_password : ${local.db_password}
smtp_address : ${local.smtp_address}
smtp_port : ${local.smtp_port}
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
