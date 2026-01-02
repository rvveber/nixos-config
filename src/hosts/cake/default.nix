{...}: {
  imports = [
    # concrete
    ./hardware.nix
    ./customization.nix

    # abstract
    ../../module/host/add/hardware/media.nix
    ../../module/host/add/hardware/bluetooth.nix
    ../../module/host/add/hardware/ssd.nix
    ../../module/host/add/hardware/8821cu.nix
    ../../module/host/add/hardware/gpu_nvidia.nix

    ../../module/host/add/application/home-manager.nix
    ../../module/host/add/application/development.nix
    ../../module/host/add/application/gaming.nix
    ../../module/host/add/application/appimage.nix
    ../../module/host/add/application/avahi.nix

    ../../module/host/select/locale/de_DE

    ../../module/host/select/customization/frontend/wayland-hyprland/rvveber-fhud
  ];
}
