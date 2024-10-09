{...}: {
  imports = [
    # concrete
    ./hardware.nix
    ./customization.nix

    # abstract
    ../../module/add/hardware/media.nix
    ../../module/add/hardware/bluetooth.nix
    ../../module/add/hardware/ssd.nix
    ../../module/add/hardware/8821cu.nix
    ../../module/add/hardware/nvidia.nix

    ../../module/add/application/home-manager.nix
    ../../module/add/application/development.nix
    ../../module/add/application/gaming.nix

    ../../module/select/locale/de_DE
    
    ../../module/select/customization/frontend/wayland-hyprland/rvveber-fhud
  ];
}
