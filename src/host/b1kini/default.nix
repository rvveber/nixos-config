{...}: {
  imports = [
    # concrete
    ./hardware.nix
    ./customization.nix

    #abstract
    ../../module/add/hardware/media.nix
    ../../module/add/hardware/bluetooth.nix
    ../../module/add/hardware/ssd.nix

    ../../module/add/application/home-manager.nix
    ../../module/add/application/gnupg-agent.nix
    ../../module/add/application/development.nix
    ../../module/add/application/virtualization.nix
    ../../module/select/application/containerization/podman

    ../../module/select/locale/de_DE

    ../../module/select/customization/frontend/wayland-hyprland/rvveber-fhud
  ];
}
