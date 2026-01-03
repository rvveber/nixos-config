{...}: {
  imports = [
    # concrete
    ./hardware.nix
    ./customization.nix

    #abstract
    ../../module/host/add/hardware/media.nix
    ../../module/host/add/hardware/gpu_amd.nix
    ../../module/host/add/hardware/bluetooth.nix
    ../../module/host/add/hardware/ssd.nix
    ../../module/host/add/hardware/battery.nix

    ../../module/host/add/application/home-manager.nix
    ../../module/host/add/application/gnupg-agent.nix
    ../../module/host/add/application/development.nix
    ../../module/host/add/application/virtualization.nix
    ../../module/host/add/application/avahi.nix
    ../../module/host/select/application/containerization/docker
    ../../module/host/add/application/gaming.nix

    ../../module/host/select/locale/de_DE

    ../../module/host/select/customization/frontend/wayland-hyprland/rvveber-fhud
  ];
}
