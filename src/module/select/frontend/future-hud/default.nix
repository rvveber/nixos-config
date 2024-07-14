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
    xdg-desktop-portal-hyprland
    hyprpaper
    hyprpicker
    ags
    wofi
    kitty
  ];

  programs.hyprland.enable = true;
  programs.hyprlock.enable = true;

  home-manager.sharedModules = [
    # Hyprland configuration
    {
      wayland.windowManager.hyprland.enable = true;
      wayland.windowManager.hyprland.settings = {
        "$mainMod" = ["SUPER"];
        "$terminal" = ["kitty"];
        "$fileManager" = ["dolphin"];
        "$menu" = ["ags -t applauncher"];
        input.kb_layout = [config.console.keyMap];
        monitor = [
          ",preferred,auto,auto"
        ];
        bind = [
          "$mainMod, Q, exec, $terminal"
          "$mainMod, C, killactive,"
          "$mainMod + SHIFT, M, exit,"
          "$mainMod, E, exec, $fileManager"
          "$mainMod, V, togglefloating,"
          "$mainMod, R, exec, $menu"
          "$mainMod, P, pseudo,"
          "$mainMod, J, togglesplit,"

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
        general = {
          gaps_in = 2;
          gaps_out = 2;
          border_size = 2;
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
