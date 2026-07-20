{config, ...}: {
  services.wireguard-client.interfaces.offsitevpn = {
    enable = true;
    configFile = config.sops.secrets.host_friday_wireguard_offsitevpn_config.path;
    configFileDependencies = ["sops-install-secrets.service"];
  };
}
