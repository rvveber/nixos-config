# Place host specific configuration here.
# (Initially copied from configuration.nix)
#
# Either if you want to override something a module defines.
# Or if you want to add something quickly, without thinking about how to encapsulate it in a module.
{
  config,
  lib,
  pkgs,
  ...
}: {
  nix.settings.experimental-features = ["nix-command" "flakes"];

  boot.initrd.luks.devices."luks-71cfbe03-2af1-4e86-b2f9-9e4ca147568b".device = "/dev/disk/by-uuid/71cfbe03-2af1-4e86-b2f9-9e4ca147568b";
  networking.hostName = "cake";
  networking.networkmanager.enable = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  environment.systemPackages = with pkgs; [
    atlauncher

    # gamedev
    godot_4-mono
  ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  services.trezord.enable = false; # not in combination with insecure packages
  services.flatpak.enable = true; # until i figured out, how to package versions

  programs.nix-ld.enable = true;

  system.stateVersion = "24.11";

  home-manager.sharedModules = [
    {
      wayland.windowManager.hyprland.settings = {
        monitor = [
          "desc:Ancor Communications Inc ASUS PB258, 2560x1440@59.95Hz, -1600x0, 1.6"
          "desc:MNR A32, 2560x1440@120.00Hz, 0x-71, 1"
        ];
      };
    }
  ];
}
