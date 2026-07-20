{config, ...}: {
  services.urbackup-client = {
    serverIdentsFile = config.sops.secrets.host_friday_urbackup_server_idents.path;
    serverIdentsFileDependencies = ["sops-install-secrets.service"];
  };
}
