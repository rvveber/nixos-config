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
  # boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;

  boot.kernelParams = ["nvidia.NVreg_PreserveVideoMemoryAllocations=1"];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices."luks-71cfbe03-2af1-4e86-b2f9-9e4ca147568b".device = "/dev/disk/by-uuid/71cfbe03-2af1-4e86-b2f9-9e4ca147568b";
  networking.hostName = "cake";
  networking.networkmanager.enable = true;

  # Enable the GNOME Desktop Environment.
  # services.xserver.displayManager.gdm.enable = true;
  # services.xserver.desktopManager.gnome.enable = true;

  environment.systemPackages = with pkgs; [
    atlauncher
    godot_4
    blender
  ];

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

  # the store can be optimised during every build. This may slow down build
  #nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  services.trezord.enable = true;

  programs.nix-ld = {
    enable = true;
    libraries = pkgs.steam-run.fhsenv.args.multiPkgs pkgs;
  };

  system.stateVersion = "24.05";
}
