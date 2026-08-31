{
  makePackages,
  source,
  stylix,
}: {
  config,
  lib,
  pkgs,
  ...
}: let
  theme = import ./theme.nix;
  appearance = import ./appearance.nix;
  packages = makePackages pkgs;
  topographyWallpaper = import ./wallpaper.nix {
    inherit pkgs source theme;
  };
in {
  # Import stylix first
  imports = [
    stylix.nixosModules.stylix
    ./lockscreen.nix
  ];

  # Install packages from this flake
  environment.systemPackages = [
    # Additional FHUD-specific packages
    pkgs.hyprshade
    pkgs.hyprlock
    pkgs.jq
    pkgs.grim
    pkgs.slurp
    pkgs.satty
    pkgs.hyprpicker
    pkgs.imagemagick
    pkgs.socat

    # Icon themes - must be installed separately for proper fallback
    pkgs.papirus-icon-theme
    pkgs.adwaita-icon-theme
    pkgs.adwaita-icon-theme-legacy # Additional icon coverage for older apps
    pkgs.hicolor-icon-theme
  ];

  # Shell aliases
  # environment.shellAliases = {
  #   ssh = "kitty +kitten ssh"; # copies kitty terminfo to server you ssh into (one time run per server is enough)
  # };

  # FHUD Theme Configuration
  stylix = {
    enable = true;
    autoEnable = true;
    base16Scheme = theme;
    opacity.terminal = 0.9;
    cursor.package = pkgs.bibata-cursors;
    cursor.size = 24;
    fonts.serif = config.stylix.fonts.sansSerif;
    cursor.name = "Bibata-Modern-Ice";
    polarity = "dark";
    # background
    image = topographyWallpaper;
    # Icon theme configuration
    # Note: Stylix can only reference ONE icon package, but additional themes
    # should be installed separately in environment.systemPackages for fallback support
    icons = {
      enable = true;
      package = pkgs.papirus-icon-theme; # Primary theme
      dark = "Papirus-Dark";
    };
  };

  home-manager.sharedModules = [
    (import ./home.nix {
      inherit appearance config lib packages pkgs theme;
    })
  ];
}
