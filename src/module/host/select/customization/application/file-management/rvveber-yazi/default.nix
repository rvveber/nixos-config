# One keyboard-first file manager across the desktop, portal file pickers and
# shells. Neovim integration lives with the Neovim customization.
{
  lib,
  pkgs,
  ...
}: let
  # Graphical launchers and MIME handlers need a terminal in which to run Yazi.
  yaziDesktop = pkgs.writeShellApplication {
    name = "yazi-desktop";
    runtimeInputs = with pkgs; [kitty yazi];
    text = ''
      exec kitty --class yazi --title Yazi yazi "$@"
    '';
  };

  # Portal services receive a minimal systemd PATH. Keep the upstream chooser
  # wrapper and all commands it invokes in one closure.
  yaziFileChooser = pkgs.writeShellApplication {
    name = "yazi-file-chooser";
    runtimeInputs = with pkgs; [coreutils gnused kitty yazi];
    text = ''
      exec ${pkgs.xdg-desktop-portal-termfilechooser}/share/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh "$@"
    '';
  };
in {
  imports = [
    ../../../../../add/application/file-management.nix
  ];

  # Makes yazi-desktop available to compositor keybindings.
  environment.systemPackages = [yaziDesktop];

  xdg.portal = {
    extraPortals = [pkgs.xdg-desktop-portal-termfilechooser];
    config.hyprland = {
      # Hyprland owns compositor-specific interfaces and GTK supplies generic
      # fallbacks. File selection alone is deliberately routed through Yazi.
      default = ["hyprland" "gtk"];
      "org.freedesktop.impl.portal.FileChooser" = "termfilechooser";
    };
  };

  home-manager.sharedModules = [
    ({config, ...}: let
      colors = config.lib.stylix.colors.withHashtag;
    in {
      services.udiskie = {
        enable = true;
        # FHUD owns desktop status and notifications; udiskie stays a quiet
        # background automounter.
        notify = false;
        tray = "never";
      };

      programs.yazi = {
        enable = true;
        enableZshIntegration = true;
        # Keep the short cwd-changing shell wrapper used for terminal work.
        shellWrapperName = "y";
        settings.mgr = {
          linemode = "size";
          show_hidden = true;
        };
        keymap.mgr.prepend_keymap = [
          {
            on = "s";
            run = "search --via=fd --args='--hidden --no-ignore'";
            desc = "Search all files by name";
          }
          {
            on = "S";
            run = "search --via=rg --args='--hidden --no-ignore'";
            desc = "Search all files by content";
          }
        ];
        plugins.ranger-status = {
          package = ./plugins/ranger-status.yazi;
          setup = true;
        };
        plugins.matching-icon-colors = {
          package = ./plugins/matching-icon-colors.yazi;
          setup = true;
        };
        theme = {
          tabs = {
            sep_inner = {
              open = "";
              close = "";
            };
            sep_outer = {
              open = "";
              close = "";
            };
          };
          indicator.padding = {
            # Yazi reserves one cell on each side of ordinary rows. Matching
            # that width keeps the highlighted row from shifting horizontally.
            open = " ";
            close = " ";
          };
          mgr.marker_symbol = "";
          status = {
            sep_left = {
              open = "";
              close = "";
            };
            sep_right = {
              open = "";
              close = "";
            };
          };
          which.separator = " ";
          notify = {
            icon_info = "i";
            icon_warn = "!";
            icon_error = "x";
          };
          cmp = {
            icon_file = "";
            icon_folder = "";
            icon_command = "";
          };
          filetype.rules = lib.mkForce [
            {
              url = "*/";
              fg = colors.base0D;
            }
            {
              url = "*";
              fg = colors.base05;
            }
          ];
        };
      };

      # Yazi's fzf picker uses the standard fzf candidate command.
      home.sessionVariables.FZF_DEFAULT_COMMAND = "${lib.getExe pkgs.fd} --hidden --no-ignore";

      xdg = {
        # Terminal applications need a desktop entry to act as an XDG
        # directory handler.
        desktopEntries.yazi = {
          name = "Yazi";
          comment = "Browse files in the terminal";
          exec = "${lib.getExe yaziDesktop} %f";
          icon = "utilities-terminal";
          terminal = false;
          categories = ["System" "FileTools" "FileManager"];
          mimeType = ["inode/directory"];
        };
        configFile."xdg-desktop-portal-termfilechooser/config".text = ''
          [filechooser]
          cmd=${yaziFileChooser}/bin/yazi-file-chooser
          # Start in home when an application supplies no useful location.
          default_dir=$HOME
          # Respect an application's location for opening; remember the last
          # location for repeated saves.
          open_mode=suggested
          save_mode=last
        '';
        mimeApps = {
          enable = true;
          defaultApplications."inode/directory" = ["yazi.desktop"];
        };
      };
    })
  ];
}
