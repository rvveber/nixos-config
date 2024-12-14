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
    godot_4
    blender
  ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  services.trezord.enable = true;
  services.flatpak.enable = true; # until i figured out, how to package versions

  programs.nix-ld.enable = true;

  system.stateVersion = "24.11";

  home-manager.sharedModules = [
    {
      wayland.windowManager.hyprland.settings = {
        monitor = [
          "DP-3,2560x1440@59.95Hz,0x0,1"
          "HDMI-A-1,2560x1440@119.99Hz,2560x0,1"
        ];
      };
    }
  ];
}
