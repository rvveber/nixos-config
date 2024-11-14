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
    enable = false; # in rootless mode, the uid and gid of your user need to be mapped correctly, or the files in the container will be owned as root (0)
    setSocketVariable = true;
  };
}
