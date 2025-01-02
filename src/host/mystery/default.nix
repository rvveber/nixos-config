{...}: {
  imports = [
    # concrete
    ./hardware.nix
    ./customization.nix

    # abstract
    ../../module/add/hardware/ssd.nix

    ../../module/select/locale/de_DE
  ];
}
