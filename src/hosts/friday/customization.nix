{
  config,
  pkgs,
  ...
}: {
  networking = {
    hostName = "friday";
  };

  system.stateVersion = "25.11";

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    efi.efiSysMountPoint = "/boot";
  };

  zramSwap = {
    enable = true;
    memoryPercent = 40;
  };

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
    settings.experimental-features = ["nix-command" "flakes"];
  };

  services.openssh = {
    enable = true;
    openFirewall = true;

    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];

    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      UsePAM = true;

      # Strict PQ/hybrid KEX algorithm
      KexAlgorithms = [
        "mlkem768x25519-sha256"
      ];
    };
  };
}
