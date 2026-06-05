version: '3.8'
services:
  gitlab:
    image: 'gitlab/gitlab-ce:19.0.1-ce.0'
    hostname: '${host_domain}'
    container_name: ${gitlab_container_name}
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'https://${host_domain}'
        letsencrypt['enable'] = false
        nginx['ssl_certificate'] = "/etc/gitlab/ssl/${host_domain}.crt"
        nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/${host_domain}.key"
        gitlab_rails['gitlab_shell_ssh_port'] = 2222
%{ if enable_s3_artifacts }
        gitlab_rails['artifacts_enabled'] = true
        gitlab_rails['artifacts_object_store_enabled'] = true
        gitlab_rails['artifacts_object_store_remote_directory'] = '${bucket_name}'
        gitlab_rails['artifacts_object_store_connection'] = {
          'provider'        => 'AWS',
          'region'          => '${region}',
          'use_iam_profile' => true
        }
%{ endif }
    ports:
      - '2222:22'
      - '443:443'
    volumes:
      - '$GITLAB_HOME/config:/etc/gitlab'
      - '$GITLAB_HOME/logs:/var/log/gitlab'
      - '$GITLAB_HOME/data:/var/opt/gitlab'
    restart: always
