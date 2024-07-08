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
    ags
    wofi
    kitty
  ];

  stylix = {
    enable = true;
    cursor.package = pkgs.breeze-hacked-cursor-theme;
    cursor.name = "Breeze_Hacked";
    polarity = "dark";
    image = ./assets/panorama.jpg;
  };
}
