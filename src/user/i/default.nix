{...}: {
  imports = [
    # abstract
    ../../module/add/application/home-manager.nix
    ../../module/select/customization/application/neovim/rvveber-nvim

    # concrete
    ./customization.nix
  ];
}
