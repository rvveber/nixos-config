{
  config,
  sops-nix,
  ...
}: {
  imports = [
    sops-nix.nixosModules.sops
  ];

  sops.defaultSopsFile = ./secrets.yaml;
  sops.defaultSopsFormat = "yaml";

  # Use the host's SSH key for decryption at runtime
  sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];

  # Define secrets here
  # These will be decrypted to /run/secrets/<name>.
  sops.secrets.host_friday_k8s_lldap_admin_password = {};
  sops.secrets.host_friday_k8s_lldap_jwt_secret = {};
  sops.secrets.host_friday_k8s_lldap_database_url = {};
  sops.secrets.host_friday_k8s_postgres_admin_password = {};
  sops.secrets.host_friday_k8s_postgres_lldap_password = {};
  sops.secrets.host_friday_k8s_postgres_stalwart_password = {};
  sops.secrets.host_friday_k8s_stalwart_dkim_private_key = {};
  sops.secrets.host_friday_k8s_cloudflare_api_token = {};

  sops.secrets.user_i_nas_smb_server_host = {};
  sops.secrets.user_i_nas_smb_shares = {};
  sops.secrets.user_i_nas_smb_auth_username = {};
  sops.secrets.user_i_nas_smb_auth_password = {};

  sops.templates.user_i_nas_smb_mount_credentials = {
    content = ''
      username=${config.sops.placeholder.user_i_nas_smb_auth_username}
      password=${config.sops.placeholder.user_i_nas_smb_auth_password}
    '';
  };
}
