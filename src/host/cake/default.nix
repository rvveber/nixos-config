{...}: {
  imports = [
    ./hardware-configuration.nix
    ./configuration.nix

    ../../module/select/locale/de_DE.nix
    ../../module/select/frontend/future-hud

    ../../module/add/hardware/audio.nix
    ../../module/add/hardware/8821cu.nix
    ../../module/add/hardware/nvidia.nix
    ../../module/add/hardware/bluetooth.nix

    ../../module/add/software/home-manager.nix
    ../../module/add/software/gaming.nix
    ../../module/add/software/development.nix
  ];
}
