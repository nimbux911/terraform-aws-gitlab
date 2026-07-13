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
%{ if smtp_enabled }
        gitlab_rails['smtp_enable'] = true
        gitlab_rails['smtp_address'] = '${smtp_address}'
        gitlab_rails['smtp_port'] = ${smtp_port}
        gitlab_rails['smtp_user_name'] = '${smtp_user_name}'
        gitlab_rails['smtp_password'] = '${smtp_password}'
        gitlab_rails['smtp_domain'] = '${smtp_domain}'
        gitlab_rails['smtp_authentication'] = '${smtp_authentication}'
        gitlab_rails['smtp_enable_starttls_auto'] = ${smtp_enable_starttls_auto}
        gitlab_rails['gitlab_email_enabled'] = true
        gitlab_rails['gitlab_email_from'] = '${gitlab_email_from}'
        gitlab_rails['gitlab_email_reply_to'] = '${gitlab_email_reply_to}'
%{ endif }
%{ if bitbucket_omniauth_enabled }
        gitlab_rails['omniauth_enabled'] = true
        gitlab_rails['omniauth_allow_single_sign_on'] = ['bitbucket']
%{ if !bitbucket_sign_in_enabled }
        gitlab_rails['omniauth_auto_sign_in_with_provider'] = false
%{ endif }
        gitlab_rails['omniauth_providers'] = [
          {
            name: 'bitbucket',
            app_id: '${bitbucket_app_id}',
            app_secret: '${bitbucket_app_secret}',
            url: '${bitbucket_url}'
          }
        ]
%{ endif }
%{ if bitbucket_import_enabled }
        gitlab_rails['import_sources'] = ['bitbucket']
%{ endif }
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
