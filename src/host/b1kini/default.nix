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
    ../../module/add/application/avahi.nix
    ../../module/select/application/containerization/docker
    ../../module/add/application/gaming.nix

    ../../module/select/locale/de_DE

    ../../module/select/customization/frontend/wayland-hyprland/rvveber-fhud
  ];
}
