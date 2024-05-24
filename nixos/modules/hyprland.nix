{ pkgs, ... }:

{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  environment.sessionVariables.ELECTRON_OZONE_PLATFORM_HINT = "1"; # This variable fixes electron apps in wayland
}
