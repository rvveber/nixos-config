{
  config,
  pkgs,
  lib,
  stylix,
  ...
}: {
  imports = [
    ../../../add/software/home-manager.nix
    stylix.nixosModules.stylix
  ];

  programs.hyprland = {
    enable = true;
  };

  environment.systemPackages = with pkgs; [
    hyprpaper
    hyprlock
    hyprpicker
    xdg-desktop-portal-hyprland
    ags
    wofi
    kitty
  ];

  stylix = {
    enable = false;
    cursor.package = pkgs.breeze-hacked-cursor-theme;
    cursor.name = "Breeze_Hacked";
    polarity = "dark";
  };
}
