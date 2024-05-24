{ pkgs, ... }:

{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;


    enableNvidiaPatches = true; # ONLY use this line if you have an nvidia card  
  };

  environment.sessionVariables.ELECTRON_OZONE_PLATFORM_HINT = "1"; # This variable fixes electron apps in wayland
}
