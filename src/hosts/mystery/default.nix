{...}: {
  imports = [
    # concrete
    ./hardware.nix
    ./customization.nix

    # abstract
    ../../module/host/add/hardware/ssd.nix

    ../../module/host/select/locale/de_DE
  ];
}
