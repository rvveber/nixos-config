{
  description = "rvveber-fhud: A modern Hyprland shell with AGS widgets";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Import the inner widget flake
    rvveber-shell.url = "path:./src/widgets/rvveber-shell";

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    rvveber-shell,
    stylix,
    ...
  }: let
    forAllSystems = nixpkgs.lib.genAttrs ["x86_64-linux" "aarch64-linux"];

    # Helper function to create script packages from external script files
    makeScriptPackage = pkgs: name: dependencies:
      pkgs.writeShellScriptBin "rvveber-fhud-${name}" ''
        # Set PATH to include all dependencies
        export PATH="${pkgs.lib.makeBinPath dependencies}:$PATH"

        # Execute the external script file content
        exec ${pkgs.bash}/bin/bash ${self}/src/scripts/${name}.sh "$@"
      '';
  in {
    packages = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      # Script packages using external files from src/scripts/ directory
      take-screenshot = makeScriptPackage pkgs "take-screenshot" [
        pkgs.grim
        pkgs.slurp
        pkgs.hyprland
        pkgs.hyprpicker
        pkgs.jq
        pkgs.satty
        pkgs.wl-clipboard
        pkgs.xdg-user-dirs
        pkgs.libavif
      ];

      lock-and-suspend = makeScriptPackage pkgs "lock-and-suspend" [
        pkgs.hyprlock
        pkgs.systemd
        pkgs.hyprland
        pkgs.procps
      ];

      paste-timestamp = makeScriptPackage pkgs "paste-timestamp" [
        pkgs.wl-clipboard
      ];

      handle-monitor-change = makeScriptPackage pkgs "handle-monitor-change" [
        pkgs.socat
        pkgs.hyprland
      ];

      switch-workspace-group = makeScriptPackage pkgs "switch-workspace-group" [
        pkgs.hyprland
        pkgs.jq
      ];

      move-to-workspace-group = makeScriptPackage pkgs "move-to-workspace-group" [
        pkgs.hyprland
        pkgs.jq
        pkgs.gawk
      ];

      app-launcher = makeScriptPackage pkgs "app-launcher" [
        rvveber-shell.packages.${system}.default
      ];

      # UI package comes from the inner flake
      ui = rvveber-shell.packages.${system}.default;

      # Default package is the UI
      default = self.packages.${system}.ui;
    });

    nixosModules.default = {
      config,
      pkgs,
      lib,
      ...
    }: let
      theme = {
        slug = "FHUD";
        author = "github.com/rvveber";
        scheme = "FHUD";
        base00 = "#050e10"; # BACKGROUND (near-black)
        base01 = "#1c3b42"; # ALT-BACKGROUND (very dark grey)
        base02 = "#1c3b42"; # SELECTION-BG (mid grey)
        base03 = "#1c3b42"; # COMMENTS / BRIGHT-BLACK (grey)
        base04 = "#1c3b42"; # DIM-FOREGROUND (soft grey)
        base05 = "#8eeaff"; # FOREGROUND (default text)
        base06 = "#d3f7ff"; # LIGHT-FOREGROUND (almost white)
        base07 = "#ffffff"; # BRIGHT-FOREGROUND (white)
        base08 = "#ed8ca8"; # ERROR (red)
        base09 = "#e4d386"; # CRITICAL / URGENT (orange)
        base0A = "#f2e8b5"; # WARNING (yellow)
        base0B = "#33ffaa"; # SUCCESS (green)
        base0C = "#33daff"; # DEBUG (cyan)
        base0D = "#33daff"; # INFO (blue)
        base0E = "#33daff"; # PROMPT / HEADING / ACCENT (magenta)
        base0F = "#33daff"; # TRACE / MISC (brown / alternative accent)
        base10 = "#e44471"; # BRIGHT-ERROR (bright red)
        base11 = "#e44471"; # BRIGHT-CRITICAL (bright orange)
        base12 = "#e44471"; # BRIGHT-WARNING (bright yellow)
        base13 = "#e5be0c"; # BRIGHT-SUCCESS (bright green)
        base14 = "#33daff"; # BRIGHT-DEBUG (bright cyan)
        base15 = "#33daff"; # BRIGHT-INFO (bright blue)
        base16 = "#33daff"; # BRIGHT-PROMPT (bright magenta)
        base17 = "#33daff"; # BRIGHT-TRACE / BRIGHT-MISC (bright brown / extra accent)
      };
      topographyWallpaperParams = {
        OUTPUT_WIDTH = 4096;
        OUTPUT_HEIGHT = 2560;
        WORK_BASE_RESOLUTION = 2500;
        CONTOUR_LEVEL_COUNT = 10;
        OUTER_LINE_DARK_FRACTION = 38;
        BASE_STROKE_WIDTH_PX = 1.5;
        TOP_THICK_LEVEL_COUNT = 2;
        TOP_THICK_STROKE_FACTOR = 2.0;
        OUTER_DARK_LINE_OPACITY = 0.3;
        INNER_LIGHT_LINE_OPACITY = 0.8;
        DASH_EVERY_NTH_LEVEL = 0;
        DASH_PATTERN_PX = "30,50";
        DASH_OFFSET_PX = 0;
        SYMBOL_EVERY_NTH_LEVEL = 0;
        SYMBOL_SHAPE = "pipe";
        SYMBOL_SIZE_PX = 20;
        SYMBOL_STROKE_PX = 0.3;
        SYMBOL_SPACING_PX = 32;
        SYMBOL_OPACITY = 0.5;
        SYMBOL_KEEP_BASE_LINE = false;
        SYMBOL_ROTATE_WITH_PATH = true;
        VIGNETTE_INSET_X_PX = 0;
        VIGNETTE_INSET_Y_PX = 150;
        VIGNETTE_COLOR = theme.base00;
        VIGNETTE_OPACITY = 1.0;
        VIGNETTE_EXPONENT = 1.8;
        LARGE_BLOB_GRID_X = 1;
        LARGE_BLOB_GRID_Y = 3;
        SMALL_BLOB_GRID_X = 3;
        SMALL_BLOB_GRID_Y = 6;
        LARGE_BLOB_STRENGTH = 1.0;
        SMALL_BLOB_STRENGTH = 0.6;
        BLOB_POSITION_JITTER = 0.7;
        BLOB_MARGIN_FRACTION = 0.22;
        AA_SUPERSAMPLE = 1;
        BACKGROUND = theme.base00;
        FOREGROUND = theme.base05;
      };
      # Fast, smooth, non-crossing topo lines via ContourPy → SVG → rasterize
      topographyWallpaper = pkgs.runCommand "wallpaper.png" (topographyWallpaperParams
        // {
          buildInputs = [
            (pkgs.python3.withPackages (ps: [ps.numpy ps.contourpy]))
            pkgs.librsvg
            pkgs.vips
          ];
        }) ''
        export PY=python3
        export RSVG=rsvg-convert
        export VIPS=vips
        bash ${self}/src/scripts/generate-topography-wallpaper.sh
      '';
    in {
      # Import stylix first
      imports = [
        stylix.nixosModules.stylix
      ];

      # Install packages from this flake
      environment.systemPackages = [
        self.packages.${pkgs.system}.ui
        self.packages.${pkgs.system}.take-screenshot
        self.packages.${pkgs.system}.lock-and-suspend
        self.packages.${pkgs.system}.paste-timestamp
        self.packages.${pkgs.system}.handle-monitor-change
        self.packages.${pkgs.system}.switch-workspace-group
        self.packages.${pkgs.system}.move-to-workspace-group
        self.packages.${pkgs.system}.app-launcher

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
      environment.shellAliases = {
        ssh = "kitty +kitten ssh"; # copies kitty terminfo to server you ssh into
      };

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

      # Hyprland UI Configuration
      home-manager.sharedModules = [
        {
          # Enable stylix for home-manager
          stylix.enable = true;

          # Install icon themes in user profile for complete coverage
          home.packages = with pkgs; [
            papirus-icon-theme
            adwaita-icon-theme
            adwaita-icon-theme-legacy # Additional icon coverage for older apps
            hicolor-icon-theme
          ];

          # kitty configuration
          programs.kitty = {
            enable = true;
            settings = {
              confirm_os_window_close = 0;
              enable_audio_bell = false;
            };
          };

          wayland.windowManager.hyprland = {
            enable = true;
            settings = {
              # Variables from original config
              "$mainMod" = ["SUPER"];
              "$terminal" = ["kitty"];
              "$fileManager" = ["dolphin"];
              "$menu" = ["uwsm app -- /usr/bin/env rvveber-fhud-app-launcher"];
              "$take_screenshot" = ["uwsm app -- /usr/bin/env rvveber-fhud-take-screenshot"];
              "$lock_and_suspend" = ["uwsm app -- /usr/bin/env rvveber-fhud-lock-and-suspend"];
              "$paste_timestamp" = ["rvveber-fhud-paste-timestamp"];
              "$switch_workspace" = ["rvveber-fhud-switch-workspace-group"];
              "$move_to_workspace" = ["rvveber-fhud-move-to-workspace-group"];
              "$handle_monitor_change" = ["rvveber-fhud-handle-monitor-change"];

              # Input configuration
              input = {
                kb_layout = [config.console.keyMap];
                sensitivity = "0.31";
                accel_profile = "flat";
                force_no_accel = true;
              };

              # Layout and spacing
              general = {
                layout = "dwindle";
                gaps_in = 2;
                gaps_out = 2;
              };

              # Window layout behavior
              dwindle = {
                preserve_split = true;
                split_bias = 0;
                force_split = 2;
                smart_split = true;
                smart_resizing = true;
              };

              # Decoration
              decoration = {
                active_opacity = 1;
                inactive_opacity = 1;
                blur = {
                  enabled = true;
                };
              };

              # Animations
              bezier = [
                "easeInOutQuint,0.83,0,0.17,1"
                "easeOutExpo,0.16,1,0.3,1"
              ];
              animation = [
                "global,1,5,easeOutExpo"
              ];

              # Start FHUD components
              exec-once = [
                "uwsm app -- /usr/bin/env rvveber-fhud-ui"
                # "uwsm app -- hyprshade auto"
                "$handle_monitor_change"
              ];

              # AGS bindings from original
              bindn = [
                ", Escape, exec, ags request closeAll"
              ];
              bindr = [
                "CAPS, Caps_Lock, exec, ags request fetchCapsState"
              ];

              # Main keybindings (restored from original)
              bind = [
                # Application launchers
                "$mainMod, $mainMod_L, exec, $menu"
                "$mainMod, $mainMod_R, exec, $menu"
                "$mainMod, Return, exec, $terminal"
                "$mainMod, D, exec, $menu"

                # Window management
                "$mainMod, Q, killactive"
                "$mainMod, E, exec, $fileManager"
                "$mainMod, V, togglefloating"
                "$mainMod, Space, togglefloating"
                "$mainMod, F, fullscreen, 1"
                "$mainMod SHIFT, F, fullscreen, 0"
                "$mainMod, P, pseudo"
                "$mainMod, J, togglesplit"
                "$mainMod SHIFT, M, exit"
                "$mainMod, M, exit"

                # Screenshots and utilities
                ", Print, exec, $take_screenshot"
                "SHIFT, Print, exec, $take_screenshot"
                "$mainMod, S, exec, $take_screenshot"
                "$mainMod, less, exec, $paste_timestamp"
                "$mainMod, equal, exec, hyprpicker -a"

                # Lock screen
                "$mainMod, L, exec, $lock_and_suspend"

                # Kill mode
                "$mainMod SHIFT, Q, exec, hyprctl kill"

                # Focus movement with ARROWS
                "$mainMod, LEFT, movefocus, l"
                "$mainMod, RIGHT, movefocus, r"
                "$mainMod, UP, movefocus, u"
                "$mainMod, DOWN, movefocus, d"

                # Focus movement with vim keys
                "$mainMod, h, movefocus, l"
                "$mainMod, l, movefocus, r"
                "$mainMod, k, movefocus, u"
                "$mainMod, j, movefocus, d"
                "$mainMod, Tab, cyclenext"

                # Window movement
                "$mainMod SHIFT, LEFT, movewindow, l"
                "$mainMod SHIFT, RIGHT, movewindow, r"
                "$mainMod SHIFT, UP, movewindow, u"
                "$mainMod SHIFT, DOWN, movewindow, d"

                # Workspace switching with workspace groups
                "$mainMod, 1, exec, $switch_workspace 1"
                "$mainMod, 2, exec, $switch_workspace 2"
                "$mainMod, 3, exec, $switch_workspace 3"
                "$mainMod, 4, exec, $switch_workspace 4"
                "$mainMod, 5, exec, $switch_workspace 5"
                "$mainMod, 6, exec, $switch_workspace 6"
                "$mainMod, 7, exec, $switch_workspace 7"
                "$mainMod, 8, exec, $switch_workspace 8"
                "$mainMod, 9, exec, $switch_workspace 9"
                "$mainMod, 0, exec, $switch_workspace 0"

                # Move to workspace with workspace groups
                "$mainMod SHIFT, 1, exec, $move_to_workspace 1"
                "$mainMod SHIFT, 2, exec, $move_to_workspace 2"
                "$mainMod SHIFT, 3, exec, $move_to_workspace 3"
                "$mainMod SHIFT, 4, exec, $move_to_workspace 4"
                "$mainMod SHIFT, 5, exec, $move_to_workspace 5"
                "$mainMod SHIFT, 6, exec, $move_to_workspace 6"
                "$mainMod SHIFT, 7, exec, $move_to_workspace 7"
                "$mainMod SHIFT, 8, exec, $move_to_workspace 8"
                "$mainMod SHIFT, 9, exec, $move_to_workspace 9"
                "$mainMod SHIFT, 0, exec, $move_to_workspace 0"

                # Workspace group switching
                "$mainMod, bracketleft, exec, switch-workspace-group 1"
                "$mainMod, bracketright, exec, switch-workspace-group 2"
                "$mainMod, backslash, exec, move-to-workspace-group"
                "$mainMod, comma, exec, handle-monitor-change"
              ];

              # Mouse bindings
              bindm = [
                "$mainMod, mouse:272, movewindow"
                "$mainMod, mouse:273, resizewindow"
              ];

              # Lid switch binding
              bindl = [
                ", switch:on:Lid Switch, exec, $lock_and_suspend"
              ];

              windowrulev2 = [
                "suppressevent maximize, class:.*"
                "float, class:^(nm-connection-editor)$"
                "float, class:^(blueman-manager)$"
                "float, class:^(satty)$"
                "size 900 700, class:^(satty)$"
                "center, class:^(satty)$"
              ];
            };
          };
        }
      ];

      # Shader Configuration TODO: not yet working
      environment.etc."xdg/hypr/hyprshade.toml".text = ''
        [[shades]]
        name = "blue-light-filter"
        start_time = 15:45:00
        end_time = 06:00:00
      '';

      # Lockscreen Configuration
      programs.hyprlock.enable = true;
      environment.etc."xdg/hypr/hyprlock.conf".text = ''
        background {
            monitor =
            path = ${config.stylix.image}
            # all these options are taken from hyprland, see https://wiki.hyprland.org/Configuring/Variables/#blur for explanations
            blur_size = 2
            blur_passes = 2 # 0 disables blurring
            noise = 0.0117
            contrast = 1.3000
            brightness = 0.8000
            vibrancy = 0.5
            vibrancy_darkness = 0.0
        }

        # Hours
        label {
            monitor =
            text = cmd[update:1000] echo "<b><big> $(date +"%H") </big></b>"
            color = rgb(${config.lib.stylix.colors.base06})
            font_size = 55
            font_family = Geist Mono 10
            shadow_passes = 3
            shadow_size = 4

            position = 0, 220
            halign = center
            valign = center
        }

        # Minutes
        label {
            monitor =
            text = cmd[update:1000] echo "<b><big> $(date +"%M") </big></b>"
            color = rgb(${config.lib.stylix.colors.base06})
            font_size = 55
            font_family = Geist Mono 10
            shadow_passes = 3
            shadow_size = 4

            position = 0, 120
            halign = center
            valign = center
        }

        # Today
        label {
            monitor =
            text = cmd[update:18000000] echo "<b><big> "$(date +'%A')" </big></b>"
            color = rgb(${config.lib.stylix.colors.base07})
            font_size = 22
            font_family = JetBrainsMono Nerd Font 10

            position = 0, 40
            halign = center
            valign = center
        }

        # Week
        label {
            monitor =
            text = cmd[update:18000000] echo "<b> "$(date +'%d %b')" </b>"
            color = rgb(${config.lib.stylix.colors.base07})
            font_size = 18
            font_family = JetBrainsMono Nerd Font 10

            position = 0, 6
            halign = center
            valign = center
        }

        input-field {
            monitor =
            size = 250, 50
            outline_thickness = 3

            dots_size = 0.26 # Scale of input-field height, 0.2 - 0.8
            dots_spacing = 0.64 # Scale of dots' absolute size, 0.0 - 1.0
            dots_center = true
            dots_rounding = -1

            rounding = 22
            outer_color = rgb(${config.lib.stylix.colors.base00})
            inner_color = rgb(${config.lib.stylix.colors.base00})
            font_color = rgb(${config.lib.stylix.colors.base06})
            fade_on_empty = true
            placeholder_text = <i>Password...</i>

            position = 0, 120
            halign = center
            valign = bottom
        }
      '';

      # Let hyprland handle the lid switch to do custom commands
      services.logind.settings.Login.HandleLidSwitch = "ignore";
    };
  };
}
