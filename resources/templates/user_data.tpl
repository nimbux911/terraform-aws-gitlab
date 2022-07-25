#cloud-config

write_files:
  - path: /home/ubuntu/gitlab/docker-compose.yml
    permissions: '0744'
    owner: root
    content: ${docker_compose_yml}
    encoding: b64
  - path: /home/ubuntu/gitlab/install.sh
    permissions: '0744'
    owner: root
    content: ${install_script}
    encoding: b64

runcmd:
  - [ bash, /home/ubuntu/gitlab/install.sh ]
  
