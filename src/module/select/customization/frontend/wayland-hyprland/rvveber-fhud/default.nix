{
  config,
  pkgs,
  stylix,
  ...
}: {
  # dependencies
  imports = [
    ../../../../../add/application/home-manager.nix
    ../../../../../add/frontend/wayland-hyprland.nix
    stylix.nixosModules.stylix

    ./src/widgets/legacy/default.nix
    # ./src/widgets/app-launcher/default.nix
    # derivation that builds ags widgets
    # todo: extract into its own repo (flake: ./src/widgets/flake.nix) or directly make rvveber-fhud itself a flake
  ];
  environment = {
    systemPackages = with pkgs; [
      # hyprland extras
      hyprshade
      hyprlock

      # pasting
      wtype

      # scripts
      jq
      grim
      slurp
      satty
      hyprpicker
      imagemagick
    ];
  };

  # Theme
  stylix = {
    enable = true;
    autoEnable = true;
    base16Scheme = {
      slug = "FHUD";
      author = "github.com/rvveber";
      scheme = "FHUD";
      base00 = "#050e10";
      base01 = "#050e10";
      base02 = "#050e10";
      base03 = "#232d2f";
      base04 = "#3d4f51";
      base05 = "#89dfec";
      base06 = "#89dfec";
      base07 = "#89dfec";
      base08 = "#ed8ca8";
      base09 = "#e4d386";
      base0A = "#f2e8b5";
      base0B = "#33daff";
      base0C = "#33daff";
      base0D = "#33daff";
      base0E = "#33daff";
      base0F = "#33daff";
      base10 = "#050e10";
      base11 = "#050e10";
      base12 = "#e44471";
      base13 = "#e5be0c";
      base14 = "#33daff";
      base15 = "#33daff";
      base16 = "#47bcff";
      base17 = "#318bf2";
    };
    opacity.terminal = 0.9;
    cursor.package = pkgs.bibata-cursors;
    cursor.size = 24;
    fonts.serif = config.stylix.fonts.sansSerif;
    cursor.name = "Bibata-Modern-Ice";
    polarity = "dark";
    # background
    image = ./src/background/crisp_ui.png;
  };

  # Hyprland
  home-manager.sharedModules = [
    {
      stylix.enable = true;
      programs.kitty = {
        enable = true;
        settings = {
          confirm_os_window_close = 0;
          enable_audio_bell = false;
        };
      };
      wayland.windowManager.hyprland.enable = true;
      wayland.windowManager.hyprland.settings = {
        "$mainMod" = ["SUPER"];
        "$terminal" = ["kitty"];
        "$fileManager" = ["dolphin"];
        "$menu" = ["uwsm app -- /usr/bin/env rvveber-app-launcher"];
        "$take_screenshot" = ["uwsm app -- ${toString ./src/scripts/take-screenshot.sh}"];
        "$lock_and_suspend" = ["uwsm app -- ${toString ./src/scripts/lock-and-suspend.sh}"];
        "$paste_timestamp" = ["${toString ./src/scripts/paste-timestamp.sh}"];
        "$switch_workspace" = ["${toString ./src/scripts/switch-workspace-group.sh}"];
        "$move_to_workspace" = ["${toString ./src/scripts/move-to-workspace-group.sh}"];
        exec-once = [
          "uwsm app -- /usr/bin/env rvveber-fhud-widgets"
        ];
        input = {
          kb_layout = [config.console.keyMap];
          sensitivity = "0.31";
          accel_profile = "flat";
          force_no_accel = true;
        };
        bindn = ["    , Escape   , exec, ags request closeAll"];
        bindr = ["CAPS, Caps_Lock, exec, ags request fetchCapsState"];
        bind = [
          "$mainMod, $mainMod_L, exec, $menu"
          "$mainMod, $mainMod_R, exec, $menu"

          "$mainMod, Return, exec, $terminal"
          "$mainMod, Q, killactive"
          "$mainMod, E, exec, $fileManager"
          "$mainMod, V, togglefloating,"
          "$mainMod, F, fullscreen,1"
          "$mainMod + SHIFT, F, fullscreen,0"
          "$mainMod, P, pseudo"
          "$mainMod, J, togglesplit"
          "$mainMod + SHIFT, M, exit"
          "$mainMod, S, exec, $take_screenshot"
          "$mainMod, less, exec, $paste_timestamp"

          #"$mainMod SHIFT, E    , exec, ags toggle win-powermenu"
          #"$mainMod      , D    , exec, ags toggle win-applauncher"
          #"$mainMod      , V    , exec, ags toggle win-clipboard"
          #"              , Print, exec, ags toggle win-screenshot"

          # lock the screen
          "$mainMod, L, exec, hyprlock"

          # kill mode, where you can kill an app by clicking on it
          "$mainMod + SHIFT, Q, exec, hyprctl kill"

          # Move focues with mainMod + ARROWS
          "$mainMod, LEFT, movefocus, l"
          "$mainMod, RIGHT, movefocus, r"
          "$mainMod, UP, movefocus, u"
          "$mainMod, DOWN, movefocus, d"

          # Move window into direction
          "$mainMod SHIFT, LEFT, movewindow, l"
          "$mainMod SHIFT, RIGHT, movewindow, r"
          "$mainMod SHIFT, UP, movewindow, u"
          "$mainMod SHIFT, DOWN, movewindow, d"

          # Switch workspaces with mainMod + [0-9]
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

          # Move active window to a workspace with mainMod + SHIFT + [0-9]
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
        ];
        # m -> mouse
        bindm = [
          # Move/resize windows with mainMod + LMB/RMB and dragging
          "$mainMod, mouse:272, movewindow"
          "$mainMod, mouse:273, resizewindow"
        ];
        bindl = [
          ", switch:on:Lid Switch, exec, $lock_and_suspend"
        ];
        windowrulev2 = [
          "suppressevent maximize, class:.*"
        ];
        decoration = {
          active_opacity = 1;
          inactive_opacity = 1;
          blur = {
            enabled = true;
          };
          #screen_shader = "${toString ./src/shader.frag}";
        };
        general = {
          layout = "dwindle";
          gaps_in = 2;
          gaps_out = 2;
        };
        dwindle = {
          preserve_split = true;
          smart_split = true;
          smart_resizing = true;
        };
        bezier = [
          "blink,0,3,0.2,-2"
          "easeInOutQuint,0.83,0,0.17,1"
          "easeOutExpo,0.16,1,0.3,1"
        ];
        animation = [
          "global,1,5,easeOutExpo"
          #"border,1,3,blink"
          #"window,1,2,easeInOutQuint,popin 85%"
          #"layersIn,1,3,blink"
          #"fadeLayersIn,1,5,easeOutExpo"
        ];
      };
    }
  ];

  # Lockscreen
  programs.hyprlock.enable = true;
  environment.etc."xdg/hypr/hyprlock.conf".text = ''
    background {
        monitor =
        path = ${toString ./src/background/crisp_ui.png} # only png supported for now
        # all these options are taken from hyprland, see https://wiki.hyprland.org/Configuring/Variables/#blur for explanations
        blur_size = 4
        blur_passes = 3 # 0 disables blurring
        noise = 0.0117
        contrast = 1.3000
        brightness = 0.8000
        vibrancy = 0.2100
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
        font_family = JetBrainsMono Nerd Font 10 #TODO: assert dependency Nerdfonts is given

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
        font_family = JetBrainsMono Nerd Font 10 #TODO: assert dependency Nerdfonts is given

        position = 0, 6
        halign = center
        valign = center
    }

    # # Degrees
    # label {
    #     monitor =
    #     text = cmd[update:18000000] echo "<b>Feels like<big> $(curl -s 'wttr.in?format=%t' | tr -d '+') </big></b>"
    #     color = rgb(${config.lib.stylix.colors.base07})
    #     font_size = 18
    #     font_family = Geist Mono 10

    #     position = 0, 40
    #     halign = center
    #     valign = bottom
    # }

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
        placeholder_text = <i>Password...</i> # Text rendered in the input box when it's empty.

        position = 0, 120
        halign = center
        valign = bottom
    }
  '';

  # Let hyprland handle the lid switch to do custom commands
  services.logind.lidSwitch = "ignore";
}
