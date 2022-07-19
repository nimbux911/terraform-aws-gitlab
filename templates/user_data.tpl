#cloud-config

write_files:
  - path: /home/ubuntu/gitlab/docker-compose.yml
    permissions: '0744'
    owner: ubuntu
    content: ${docker_compose_yml}
    encoding: b64
  - path: /home/ubuntu/gitlab/install.sh
    permissions: '0744'
    owner: ubuntu
    content: ${install_script}
    encoding: b64

runcmd:
  - /home/ubuntu/gitlab/install.sh
