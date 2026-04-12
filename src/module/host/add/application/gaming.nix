{
  lib,
  pkgs,
  config,
  ...
}: {
  # boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;
  environment.systemPackages = [
    pkgs.protonplus
    pkgs.mangohud
  ];
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = false; # Optional: Open ports in the firewall for Steam Remote Play
    localNetworkGameTransfers.openFirewall = false; # Optional: Open ports in the firewall for Steam Local Network Game Transfers
    dedicatedServer.openFirewall = false; # Optional: Open ports in the firewall for Source Dedicated Server
  };
  programs.gamescope.enable = true;
  programs.gamemode.enable = true;
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "steam"
      "steam-original"
      "steam-run"
    ];
}
