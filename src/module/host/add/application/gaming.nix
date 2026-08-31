{
  lib,
  pkgs,
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

  programs.gamescope = {
    enable = true;
    enableWsi = true;
    capSysNice = false;

    package = pkgs.gamescope.overrideAttrs (old: {
      postPatch =
        (old.postPatch or "")
        + ''
          substituteInPlace src/Utils/Process.cpp \
            --replace-fail \
              'RestoreFdLimit();' \
              'prctl(PR_CAP_AMBIENT, PR_CAP_AMBIENT_LOWER, 23, 0, 0); RestoreFdLimit();'
        '';
    });
  };

  programs.gamemode = {
    enable = true;
    enableRenice = true;

    settings = {
      general = {
        desiredgov = "performance";
        desiredprof = "performance";
        renice = 10;
        ioprio = 0;
      };
    };
  };

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "steam"
      "steam-original"
      "steam-run"
    ];
}
