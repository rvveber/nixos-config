# Configures Hyprlock and delegates lid-switch behavior to Hyprland.
{config, ...}: {
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
}
