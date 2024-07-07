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
}
