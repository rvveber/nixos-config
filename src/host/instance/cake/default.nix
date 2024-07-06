{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./configuration.nix

    ../../module/select/locale/de_DE.nix
    ../../module/select/theme/future-hud

    ../../module/add/hardware/audio.nix
    ../../module/add/hardware/8821cu.nix
    ../../module/add/hardware/nvidia.nix

    ../../module/add/software/gaming.nix
  ];
}
