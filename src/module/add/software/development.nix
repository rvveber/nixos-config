{
  pkgs,
  config,
  ...
}: {
  programs.direnv.enable = true;
  environment.systemPackages = [
    pkgs.devenv
    pkgs.git
  ];
  virtualisation.docker.enable = true;
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };
}
