{config, ...}: let
  sopsFile = ./secrets.yaml;
in {
  sops.secrets.user_i_nas_smb_server_host = {inherit sopsFile;};
  sops.secrets.user_i_nas_smb_shares = {inherit sopsFile;};
  sops.secrets.user_i_nas_smb_auth_username = {inherit sopsFile;};
  sops.secrets.user_i_nas_smb_auth_password = {inherit sopsFile;};

  sops.templates.user_i_nas_smb_mount_credentials = {
    content = ''
      username=${config.sops.placeholder.user_i_nas_smb_auth_username}
      password=${config.sops.placeholder.user_i_nas_smb_auth_password}
    '';
  };
}
