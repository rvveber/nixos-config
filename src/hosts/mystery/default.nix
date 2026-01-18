{...}: {
  imports = [
    # concrete
    ./hardware.nix
    ./disko.nix
    ./customization.nix

    # abstract
    ../../module/host/add/hardware/ssd.nix

    ../../module/host/select/locale/de_DE
  ];
}
