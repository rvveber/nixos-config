{...}: {
  imports = [
    # concrete
    ./hardware.nix
    ./disko-config.nix
    ./customization.nix

    # abstract
    ../../module/host/add/hardware/ssd.nix

    ../../module/host/select/locale/de_DE
  ];
}
