version: "1"
services:
  gitlab:
    image: gitlab/gitlab-ce:latest
    hostname: gitlab.ops.alaskaops.io
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'https://gitlab.ops.alaskaops.io'
    ports:
      - 22:22
      - 80:80
      - 443:443
    volumes:
      gitlab_config:/etc/gitlab
      gitlab_logs:/var/log/gitlab
      gitlab_data:/var/opt/gitlab
    restart: unless-stopped
volumes:
  gitlab_config:
  gitlab_logs:
  gitlab_data:
