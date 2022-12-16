#cloud-config

write_files:
  - path: /home/ubuntu/install.sh
    permissions: '0744'
    owner: root
    content: ${install_script}
    encoding: b64
  - path: /home/ubuntu/backup.sh
    permissions: '0744'
    owner: root
    content: ${backup_script}
    encoding: b64

runcmd:
  - [ bash, /home/ubuntu/install.sh ]