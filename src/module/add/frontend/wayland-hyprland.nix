{pkgs, ...}: {
  # dependencies
  environment = {
    systemPackages = with pkgs; [
      # wayland essentials
      wl-clipboard

      # hyprland essentials
      xdg-desktop-portal-hyprland

      # hyprland extras
      hyprpaper
      hyprland-workspaces
      hyprpicker
    ];
    sessionVariables = {
      # Suggest applications to use native wayland instead of xorg (xwayland)
      NIXOS_OZONE_WL = "1";
    };
  };

  programs = {
    hyprland.enable = true;
  };
}
