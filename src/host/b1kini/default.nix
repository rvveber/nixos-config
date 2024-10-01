{...}: {
  imports = [
    # concrete
    ./hardware.nix
    ./customization.nix

    # abstract
    ../../module/add/purpose/development.nix
    ../../module/add/purpose/containerization.nix
    ../../module/add/purpose/virtualization.nix

    ../../module/add/hardware/media.nix
    ../../module/add/hardware/bluetooth.nix
    ../../module/add/hardware/ssd.nix

    ../../module/add/application/home-manager.nix
    ../../module/add/application/gnupg-agent.nix

    ../../module/select/locale/de_DE
    ../../module/select/customization/frontend/wayland-hyprland/rvveber-fhud
  ];
}
