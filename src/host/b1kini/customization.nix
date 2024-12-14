# host specific configuration that can't be encapsulated in re-usable modules atm.
{
  config,
  pkgs,
  ...
}: {
  nix.settings.experimental-features = ["nix-command" "flakes"];

  networking.hostName = "b1kini";
  networking.networkmanager.enable = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  system.stateVersion = "24.11";
  home-manager.sharedModules = [
    {
      wayland.windowManager.hyprland.settings = {
        monitor = [
          "DP-2,2560x1440@59.95Hz,0x0,1.6"
          "HDMI-A-1,2560x1440@59.95Hz,1600x0,1"
          "eDP-1,2880x1800@120.00Hz,4160x0,2"
        ];
      };
    }
  ];
}
