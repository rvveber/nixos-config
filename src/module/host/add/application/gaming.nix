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
    pkgs.gamescope # TODO: remove after future update
  ];
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = false; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = false; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = false; # Open ports in the firewall for Steam Local Network Game Transfers
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
