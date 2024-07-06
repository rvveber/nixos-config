{ config, pkgs, homeDirectory ? null, ... }:

let
  linkConfigurationToUser = if homeDirectory != null then {
    "${homeDirectory}/.config/hypr/hyprland.conf".source = "./etc/hypr/hyprland.conf";
  } else {};
in

{
  # Conditionally link the file based on homeDirectory
  inherit (linkConfigurationToUser) environment;

  programs.hyprland = {
    enable = true;
  };
  environment.systemPackages = with pkgs; [
    ags
    wofi
    kitty
  ];
}