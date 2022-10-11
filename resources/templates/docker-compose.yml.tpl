version: '3.8'
services:
  gitlab:
    image: 'gitlab/gitlab-ce:15.2.5-ce.0'
    hostname: '${host_domain}'
    container_name: gitlab
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'https://${host_domain}'
        letsencrypt['enable'] = false
        nginx['ssl_certificate'] = "/etc/gitlab/ssl/${host_domain}.crt"
        nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/${host_domain}.key"
        gitlab_rails['gitlab_shell_ssh_port'] = 2222
    ports:
      - '2222:22'
      - '443:443'
    volumes:
      - '$GITLAB_HOME/config:/etc/gitlab'
      - '$GITLAB_HOME/logs:/var/log/gitlab'
      - '$GITLAB_HOME/data:/var/opt/gitlab'
    restart: always
