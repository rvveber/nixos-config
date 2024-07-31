# host specific configuration that can't be encapsulated in re-usable modules atm.
{
  config,
  lib,
  ...
}: {
  nix.settings.experimental-features = ["nix-command" "flakes"];

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernel.sysctl = {"vm.swappiness" = 70;};
  #boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices."luks-71cfbe03-2af1-4e86-b2f9-9e4ca147568b".device = "/dev/disk/by-uuid/71cfbe03-2af1-4e86-b2f9-9e4ca147568b";
  networking.hostName = "cake";
  networking.networkmanager.enable = true;

  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    mullvad-vpn
    steam-run
    atlauncher
    spotify
    neovim
    vscode
    chromium
    pureref
    btop
    flameshot
    inkscape
  ];

  nixpkgs.config = {
    chromium = {
      enableWideVine = true;
    };
  };

  services.mullvad-vpn.enable = true;

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

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 32 * 1024;
    }
  ];

  programs.nix-ld = {
    enable = true;
    libraries = pkgs.steam-run.fhsenv.args.multiPkgs pkgs;
  };

  system.stateVersion = "24.05";
}
