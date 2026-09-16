# Provides the shared NixOS and Home Manager foundation for a Hyprland desktop.
{pkgs, ...}: let
  luaCall = args: {_args = args;};
in {
  # Ask GTK applications, including Steam's GTK helper dialogs, to use the
  # desktop portal selected by the active Wayland customization.
  environment.sessionVariables.GTK_USE_PORTAL = "1";

  # dependencies
  environment = {
    systemPackages = with pkgs; [
      # wayland essentials
      wl-clipboard
      xdg-desktop-portal-gtk

      # hyprland essentials
      xdg-desktop-portal-hyprland

      # hyprland extras
      hyprpaper
      hyprland-workspaces
      hyprpicker
      hyprcursor

      # common tooling for xwayland apps
      xrandr
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
          config = {
            general.allow_tearing = true;
            render = {
              direct_scanout = 1;
              new_render_scheduling = false;
            };
            debug.disable_logs = true;
            misc = {
              force_default_wallpaper = 0;
              disable_hyprland_logo = true;
            };
            xwayland = {
              force_zero_scaling = false;
              use_nearest_neighbor = true;
            };
          };
          env = [
            (luaCall ["NIXOS_OZONE_WL" "1"])
            (luaCall ["QT_AUTO_SCREEN_SCALE_FACTOR" "1"])
            (luaCall ["QT_QPA_PLATFORM" "wayland"])
            (luaCall ["QT_WAYLAND_DISABLE_WINDOWDECORATION" "1"])
          ];
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
