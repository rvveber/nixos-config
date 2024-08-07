{
  config,
  pkgs,
  lib,
  stylix,
  home-manager,
  ...
}: {
  imports = [
    ../../../add/software/home-manager.nix
    stylix.nixosModules.stylix
  ];

  # Frontend choices
  environment.systemPackages = with pkgs; [
    # hyprland essentials
    xdg-desktop-portal-hyprland
    hyprpaper
    hyprpicker
    hyprlock

    # theme essentials
    wl-clipboard
    ags
    wofi
    kitty

    # screenshots
    grim
    slurp
    satty
  ];

  programs.hyprland.enable = true;
  programs.hyprlock.enable = true;

  # Suggest applications to use native wayland instead of xorg (xwayland)
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Stylix configuration
  stylix = {
    enable = true;
    autoEnable = true;
    base16Scheme = {
      slug = "FHUD";
      author = "github.com/rvveber";
      scheme = "FHUD";
      base00 = "#020708";
      base01 = "#040b0c";
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
      base10 = "#040b0c";
      base11 = "#020708";
      base12 = "#e44471";
      base13 = "#e5be0c";
      base14 = "#33daff";
      base15 = "#33daff";
      base16 = "#47bcff";
      base17 = "#318bf2";
    };
    cursor.package = pkgs.bibata-cursors;
    fonts.serif = config.stylix.fonts.sansSerif;
    cursor.name = "Bibata-Modern-Ice";
    polarity = "dark";
    image = ./assets/background/scene.png;
    opacity.terminal = 0.5;
  };

  home-manager.sharedModules = [
    {
      stylix.enable = true;
      wayland.windowManager.hyprland.enable = true;
      wayland.windowManager.hyprland.settings = {
        "$mainMod" = ["SUPER"];
        "$terminal" = ["kitty"];
        "$fileManager" = ["dolphin"];
        "$menu" = ["ags -t applauncher"];
        "$screenshot" = ["${toString ./assets/scripts/take-screenshot.sh}"];
        debug.disable_logs = false;
        input = {
          kb_layout = [config.console.keyMap];
          sensitivity = "0.4";
          accel_profile = "flat";
        };
        monitor = [
          ",preferred,auto,auto"
        ];
        bind = [
          "$mainMod, Q, exec, $terminal"
          "$mainMod, C, killactive"
          "$mainMod + SHIFT, M, exit"
          "$mainMod, E, exec, $fileManager"
          "$mainMod, V, togglefloating,"
          "$mainMod, R, exec, $menu"
          "$mainMod, S, exec, $screenshot"
          "$mainMod, P, pseudo"
          "$mainMod, J, togglesplit"

          # Switch workspaces with mainMod + [0-9]
          "$mainMod, 1, workspace, 1"
          "$mainMod, 2, workspace, 2"
          "$mainMod, 3, workspace, 3"
          "$mainMod, 4, workspace, 4"
          "$mainMod, 5, workspace, 5"
          "$mainMod, 6, workspace, 6"
          "$mainMod, 7, workspace, 7"
          "$mainMod, 8, workspace, 8"
          "$mainMod, 9, workspace, 9"
          "$mainMod, 0, workspace, 10"

          # Move active window to a workspace with mainMod + SHIFT + [0-9]
          "$mainMod SHIFT, 1, movetoworkspace, 1"
          "$mainMod SHIFT, 2, movetoworkspace, 2"
          "$mainMod SHIFT, 3, movetoworkspace, 3"
          "$mainMod SHIFT, 4, movetoworkspace, 4"
          "$mainMod SHIFT, 5, movetoworkspace, 5"
          "$mainMod SHIFT, 6, movetoworkspace, 6"
          "$mainMod SHIFT, 7, movetoworkspace, 7"
          "$mainMod SHIFT, 8, movetoworkspace, 8"
          "$mainMod SHIFT, 9, movetoworkspace, 9"
          "$mainMod SHIFT, 0, movetoworkspace, 10"
        ];
        bindm = [
          # Move/resize windows with mainMod + LMB/RMB and dragging
          "$mainMod, mouse:272, movewindow"
          "$mainMod, mouse:273, resizewindow"
        ];
        windowrulev2 = [
          "suppressevent maximize, class:.*"
        ];
        decoration = {
          active_opacity = 1;
          inactive_opacity = 1;
        };
        general = {
          layout = "dwindle";
        };
        misc = {
          force_default_wallpaper = 0;
          disable_hyprland_logo = true;
        };
        decoration = {
          blur = {
            enabled = true;
          };
        };
        xwayland = {
          force_zero_scaling = true;
        };
        bezier = [
          "blink,0,3,0.2,-2"
          "easeInOutQuint,0.83,0,0.17,1"
          "easeOutExpo,0.16,1,0.3,1"
        ];
        animation = [
          #"global,1,5,easeOutExpo"
          #"border,1,3,blink"
          #"window,1,2,easeInOutQuint,popin 85%"
          #"layersIn,1,3,blink"
          #"fadeLayersIn,1,5,easeOutExpo"
        ];
      };

      # Ags configuration
      home.file = {
        ".config/ags".source = ./assets/widgets;
      };
    }
  ];

  environment.etc."xdg/hypr/hyprlock.conf".text = ''
    background {
        monitor =
        path = ${toString ./assets/background/scene.png} # only png supported for now
        # all these options are taken from hyprland, see https://wiki.hyprland.org/Configuring/Variables/#blur for explanations
        blur_size = 4
        blur_passes = 3 # 0 disables blurring
        noise = 0.0117
        contrast = 1.3000 # Vibrant!!!
        brightness = 0.8000
        vibrancy = 0.2100
        vibrancy_darkness = 0.0
    }

    # Hours
    label {
        monitor =
        text = cmd[update:1000] echo "<b><big> $(date +"%H") </big></b>"
        color = rgb(${config.lib.stylix.colors.base06})
        font_size = 112
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
        font_size = 112
        font_family = Geist Mono 10
        shadow_passes = 3
        shadow_size = 4

        position = 0, 80
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

        position = 0, 30
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

    # Degrees
    label {
        monitor =
        text = cmd[update:18000000] echo "<b>Feels like<big> $(curl -s 'wttr.in?format=%t' | tr -d '+') </big></b>"
        color = rgb(${config.lib.stylix.colors.base07})
        font_size = 18
        font_family = Geist Mono 10

        position = 0, 40
        halign = center
        valign = bottom
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
        placeholder_text = <i>Password...</i> # Text rendered in the input box when it's empty.

        position = 0, 120
        halign = center
        valign = bottom
    }
  '';
}
