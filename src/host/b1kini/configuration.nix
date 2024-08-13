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

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    lshw-gui
    openshift
    kubectl
    kubernetes-helm
    helm-docs
  ];


  home-manager.sharedModules = [
    {
      wayland.windowManager.hyprland.settings = {
        monitor = [
          "DP-1,2560x1440@59.95Hz,0x0,1.6"
          "HDMI-A-1,2560x1440@59.95Hz,1600x0,1"
          "eDP-1,2880x1800@120.00Hz,4160x0,2"
        ];
      };
    }
  ];

  system.stateVersion = "24.05";
}
