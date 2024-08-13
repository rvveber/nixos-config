{
  pkgs,
  config,
  ...
}: {
  # TODO: incorperate into containerization.nix and make choosable via options
  virtualisation.docker.enable = true;
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };
}
