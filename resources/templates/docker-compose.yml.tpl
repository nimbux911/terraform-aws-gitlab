version: '3.8'
services:
  gitlab:
    image: 'gitlab/gitlab-ce:${image_version}'
    hostname: '${hostname}'
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'https://${hostname}'
        letsencrypt['enable'] = false
        nginx['ssl_certificate'] = "/etc/gitlab/ssl/${hostname}.crt"
        nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/${hostname}.key"
    ports:
      - '22:22'
      - '80:80'
      - '443:443'
    volumes:
      - '$GITLAB_HOME/config:/etc/gitlab'
      - '$GITLAB_HOME/logs:/var/log/gitlab'
      - '$GITLAB_HOME/data:/var/opt/gitlab'
    restart: always
