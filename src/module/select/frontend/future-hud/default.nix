{
  config,
  pkgs,
  lib,
  stylix,
  home-manager,
  ...
}: {
  # TODO: find out where the translated directory name for "Bilder/Bildschirmfotos" comes, and find a way to link it dynamically.

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

  home-manager.sharedModules = [
    # Hyprland configuration
    {
      wayland.windowManager.hyprland.enable = true;
      wayland.windowManager.hyprland.settings = {
        "$mainMod" = ["SUPER"];
        "$terminal" = ["kitty"];
        "$fileManager" = ["dolphin"];
        "$menu" = ["ags -t applauncher"];
        "$screenshot" = ["grim -g \"$(slurp -o -r -c '#ff0000ff')\" - | satty --filename - --fullscreen --output-filename ~/Bilder/Bildschirmfotos/satty-$(date '+%Y%m%d-%H:%M:%S').png"];
        input = {
          kb_layout = [config.console.keyMap];
          sensitivity = "0.5";
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
          rounding = 15;
          active_opacity = 1;
          inactive_opacity = 1;
          drop_shadow = true;
          shadow_range = 24;
          "col.shadow" = lib.mkForce "rgba(00b4ffee)";
          "col.shadow_inactive" = lib.mkForce "rgba(00000000)";
          dim_inactive = true;
          dim_strength = 0.1;
        };
        general = {
          gaps_in = 6;
          gaps_out = 12;
          border_size = 3;
          layout = "dwindle";
          "col.inactive_border" = lib.mkForce "rgba(00000000)";
          "col.active_border" = lib.mkForce "rgba(80d9ffff)";
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
          "global,1,5,easeOutExpo"
          #"border,1,3,blink"
          #"window,1,2,easeInOutQuint,popin 85%"
          #"layersIn,1,3,blink"
          #"fadeLayersIn,1,5,easeOutExpo"
        ];
      };
    }
    # Ags configuration
    {
      home.file = {
        ".config/ags".source = ./assets/configuration/ags;
      };
    }
  ];

  # Stylix configuration
  stylix = {
    enable = true;
    cursor.package = pkgs.breeze-hacked-cursor-theme;
    fonts.serif = config.stylix.fonts.sansSerif;
    cursor.name = "Breeze_Hacked";
    polarity = "dark";
    image = ./assets/background/scene.png;
    opacity.terminal = 0.5;
  };
}
