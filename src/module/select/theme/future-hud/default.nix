{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.hyprland = {
    enable = true;
  };
  environment.systemPackages = with pkgs; [
    ags
    wofi
    kitty
  ];
}
