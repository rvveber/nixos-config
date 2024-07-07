{
  pkgs,
  config,
  ...
}: {
  environment.systemPackages = [
    pkgs.protonplus
    pkgs.steam
  ];
}
