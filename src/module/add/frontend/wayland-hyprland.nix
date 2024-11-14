{
  pkgs,
  home-manager,
  ...
}: {
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
    # Universal Wayland Session Manager
    uwsm = {
      enable = true;
      waylandCompositors.hyprland = {
        binPath = "/run/current-system/sw/bin/Hyprland";
        comment = "Hyprland session managed by uwsm";
        prettyName = "Hyprland";
      };
    };
  };

  # Conflicts with uwsm
  home-manager.sharedModules = [
    {
      wayland.windowManager.hyprland.systemd.enable = false;
    }
  ];

  # Use dbus-broker instead of dbus-daemon, better perfomance
  services.dbus.implementation = "broker";

  # Shell independent login script
  environment.interactiveShellInit = ''
    if uwsm check may-start; then
      exec uwsm start hyprland-uwsm.desktop
    fi
  '';
}
