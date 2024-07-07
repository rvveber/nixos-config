{nixos-hardware, ...}: {
  imports = [
    nixos-hardware.nixosModules.tuxedo-pulse-14-gen3
    ./hardware-configuration.nix
    ./configuration.nix

    ../../module/select/locale/de_DE.nix
    ../../module/select/theme/future-hud

    ../../module/add/hardware/audio.nix
    ../../module/add/software/gnupg-agent.nix
  ];
}
