version: '3.8'
services:
  gitlab:
    image: 'gitlab/gitlab-ce:latest'
    hostname: 'gitlab.ops.alaskaops.io'
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'https://gitlab.ops.alaskaops.io'
    ports:
      - '2222:22'
      - '80:80'
      - '443:443'
    volumes:
      - '$GITLAB_HOME/config:/etc/gitlab'
      - '$GITLAB_HOME/logs:/var/log/gitlab'
      - '$GITLAB_HOME/data:/var/opt/gitlab'
    restart: always

networks:
  default:
    ipam:
      driver: default
      config:
        - subnet: ${compose_cidr}
