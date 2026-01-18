{...}: {
  imports = [
    # abstract
    ../../module/host/add/application/home-manager.nix

    # concrete
    ./customization.nix
  ];
}
