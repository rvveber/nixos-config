{...}: {
  imports = [
    # abstract
    ../../module/host/add/hardware/ssd.nix
    ../../module/host/add/application/lix.nix

    ../../module/host/select/locale/de_DE

    # concrete
    ../../secrets/secrets.nix
    ./hardware.nix
    ./disko.nix
    ./customization.nix
    ./services
  ];
}
