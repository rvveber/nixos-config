{...}: {
  imports = [
    # abstract
    ../../module/host/add/hardware/ssd.nix

    ../../module/host/select/locale/de_DE
    ../../module/host/select/application/containerization/docker

    # concrete
    ./hardware.nix
    ./disko.nix
    ./customization.nix
  ];
}
