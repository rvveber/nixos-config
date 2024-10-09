{
  pkgs,
  config,
  ...
}: {
  # dependencies
  imports = [
    ../../../../add/application/containerization.nix
  ];
  
  virtualisation.docker.enable = true;
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };
}
