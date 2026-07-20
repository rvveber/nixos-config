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

  # Grant users in the "wheel" group the ability to maximize process priority
  security.pam.loginLimits = [
    { domain = "@wheel"; type = "-"; item = "nice"; value = "-20"; }
  ];
  # use a renice command in steam launch options to maximize the priority of gamescope
  # %command% && sleep 3 && renice -n -20 -p $(pgrep gamescope)
}
