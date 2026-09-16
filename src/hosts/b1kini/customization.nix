# host specific configuration that can't be encapsulated in re-usable modules atm.
_: let
  inotifyLimit = 1048576;
  openFileLimit = 524288;
in {
  system.stateVersion = "24.11";

  nix.settings.experimental-features = ["nix-command" "flakes"];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  networking.hostName = "b1kini";
  networking.networkmanager.enable = true;

  boot.kernel.sysctl = {
    "fs.inotify.max_queued_events" = inotifyLimit;
    "fs.inotify.max_user_instances" = inotifyLimit;
    "fs.inotify.max_user_watches" = inotifyLimit;
  };

  security.pam.loginLimits = [
    {
      domain = "*";
      type = "soft";
      item = "nofile";
      value = toString openFileLimit;
    }
    {
      domain = "*";
      type = "hard";
      item = "nofile";
      value = toString openFileLimit;
    }
  ];

  systemd.settings.Manager.DefaultLimitNOFILE = openFileLimit;
  systemd.user.settings.Manager.DefaultLimitNOFILE = openFileLimit;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Screens
  rvveber.fhud.mainMonitor = "desc:Tianma Microelectronics Ltd";
  home-manager.sharedModules = [
    {
      #    0x0---------> X
      #    |
      #    |
      #    v Y
      wayland.windowManager.hyprland.settings = {
        monitor = [
          # "desc:Ancor Communications Inc ASUS PB258, 2560x1440@59.95Hz, 4000x-1200, 1, transform, 1"
          {
            output = "desc:Ancor Communications Inc ASUS PB258";
            mode = "2560x1440@59.95Hz";
            position = "0x0";
            scale = 1;
            transform = 3;
          }
          {
            output = "desc:MNR A32";
            mode = "2560x1440@165.00Hz";
            position = "1440x1028";
            scale = 1;
          }
          {
            output = "desc:Tianma Microelectronics Ltd";
            mode = "2880x1800@120.00Hz";
            position = "4000x820";
            scale = 2;
          }
        ];
        workspace_rule = [
          # See frontend/wayland-hyprland/rvveber/src/scripts/switch-workspace-group.sh for details.
          {
            workspace = "11";
            monitor = "desc:Tianma Microelectronics Ltd";
            persistent = true;
            default = true;
          }
          {
            workspace = "21";
            monitor = "desc:MNR A32";
            persistent = true;
            default = true;
          }
          {
            workspace = "31";
            monitor = "desc:Ancor Communications Inc ASUS PB258";
            persistent = true;
            default = true;
          }
        ];
      };
    }
  ];
}
