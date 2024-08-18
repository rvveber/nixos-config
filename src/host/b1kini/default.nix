{...}: {
  imports = [
    ./hardware-configuration.nix
    ./configuration.nix

    ../../module/add/software/home-manager.nix
    ../../module/select/locale/de_DE.nix
    ../../module/select/frontend/future-hud

    ../../module/add/hardware/media.nix
    ../../module/add/hardware/bluetooth.nix

    ../../module/add/software/gnupg-agent.nix
    ../../module/add/software/development.nix
    ../../module/add/software/docker.nix
  ];
}
