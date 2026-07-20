# host specific configuration that can't be encapsulated in re-usable modules atm.
_: let
  inotifyLimit = 1048576;
  openFileLimit = 524288;
in {
  nix.settings.experimental-features = ["nix-command" "flakes"];

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

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  system.stateVersion = "24.11";
  home-manager.sharedModules = [
    {
      #    0x0---------> X
      #    |
      #    |
      #    v Y
      wayland.windowManager.hyprland.settings = {
        monitor = [
          # "desc:Ancor Communications Inc ASUS PB258, 2560x1440@59.95Hz, 4000x-1200, 1, transform, 1"
          "desc:Ancor Communications Inc ASUS PB258, 2560x1440@59.95Hz, 0x0, 1, transform, 3"
          "desc:MNR A32, 2560x1440@165.00Hz, 1440x1028, 1"
          "desc:Tianma Microelectronics Ltd, 2880x1800@120.00Hz, 4000x820, 2"
        ];
        workspace = [
          # See frontend/wayland-hyprland/rvveber/src/scripts/switch-workspace-group.sh for details.
          "11, monitor:desc:Tianma Microelectronics Ltd, persistent:true, default:true"
          "21, monitor:desc:MNR A32, persistent:true, default:true"
          "31, monitor:desc:Ancor Communications Inc ASUS PB258, persistent:true, default:true"
        ];
      };
    }
  ];
}
