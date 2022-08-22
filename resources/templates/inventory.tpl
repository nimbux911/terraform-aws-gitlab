p10gitlab:
  hosts:
    ${hostname}:
      ansible_port: 2222
      ansible_ssh_private_key_file: ${pvt_key}
      ansible_user: ubuntu
      ansible_connection: ssh
