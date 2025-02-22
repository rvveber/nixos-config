# host specific configuration that can't be encapsulated in re-usable modules atm.
{
  config,
  pkgs,
  ...
}: {
  nix.settings.experimental-features = ["nix-command" "flakes"];

  networking.hostName = "mystery";
  networking.hostId = "3610905c";

  boot.loader.systemd-boot.enable = true;
  services.openssh.enable = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB+PT0eOseiYhZcs/YgrVAd5l/SLqZTwwEveGR1mGsJR"
  ];

  system.stateVersion = "24.11";
}
