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
      xdg-desktop-portal

      # hyprland essentials
      xdg-desktop-portal-hyprland

      # hyprland extras
      hyprpaper
      hyprland-workspaces
      hyprpicker
    ];
    sessionVariables = {
      # Suggest applications to use native wayland instead of xorg (xwayland)
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

  home-manager.sharedModules = [
    {
      wayland.windowManager.hyprland = {
        enable = true;
        systemd.enable = false; # Conflicts with uwsm
        settings = {
          debug.disable_logs = true;
          exec-once = [
            "uwsm app -s b -- hyprpaper"
          ];
          env = [
            "NIXOS_OZONE_WL,1"
            "QT_AUTO_SCREEN_SCALE_FACTOR,1"
            "QT_QPA_PLATFORM,wayland"
            "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
          ];
          monitor = [
            ",preferred,auto,auto"
          ];
          misc = {
            force_default_wallpaper = 0;
            disable_hyprland_logo = true;
          };
          xwayland = {
            force_zero_scaling = true;
          };
        };
      };
    }
  ];

  # Use dbus-broker instead of dbus-daemon, better perfomance
  services.dbus.implementation = "broker";

  # Shell independent login script
  environment.interactiveShellInit = ''
    if uwsm check may-start; then
      exec uwsm start -S hyprland-uwsm.desktop
    fi
  '';
}
