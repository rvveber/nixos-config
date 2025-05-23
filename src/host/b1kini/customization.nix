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
          "desc:Tianma Microelectronics Ltd, 2880x1800@120.00Hz, 0x0, 2"
          "desc:MNR A32, 2560x1440@165.00Hz, 1440x300, 1"
          "desc:Ancor Communications Inc ASUS PB258, 2560x1440@59.95Hz, 4000x300, 1, transform, 1"
        ];
      };
    }
  ];
}
