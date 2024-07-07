{ config, pkgs, lib, ... }:

#let
#  linkConfigurationToUser = if homeDirectory != null then {
#    "${homeDirectory}/.config/hypr/hyprland.conf".source = "./etc/hypr/hyprland.conf";
#  } else {};
#in

{
  programs.hyprland = {
    enable = true;
  };
  environment.systemPackages = with pkgs; [
    ags
    wofi
    kitty
  ];
}