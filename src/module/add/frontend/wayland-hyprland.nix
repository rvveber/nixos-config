{
  config,
  pkgs,
  home-manager,
  ...
}: {
  # dependencies
  environment = {
    systemPackages = with pkgs; [
      # wayland essentials
      wl-clipboard
      wtype
      xdg-desktop-portal-gtk

      # hyprland essentials
      xdg-desktop-portal-hyprland

      # hyprland extras
      hyprpaper
      hyprland-workspaces
      hyprpicker
      hyprcursor
    ];
  };

  programs = {
    uwsm.enable = true;
    hyprland = {
      enable = true;
      withUWSM = true;
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
            "NIXOS_OZONE_WL,1" # Suggest applications to use native wayland instead of xorg (xwayland)
            "QT_AUTO_SCREEN_SCALE_FACTOR,1"
            "QT_QPA_PLATFORM,wayland"
            "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
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
      exec sh -c 'uwsm start hyprland-uwsm.desktop || exec "''${SHELL:-/bin/sh}"'
    fi
  '';
}
