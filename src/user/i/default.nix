{...}: {
  imports = [
    # abstract
    ../../module/add/application/home-manager.nix
    ../../module/add/application/docker.nix
    ../../module/select/customization/application/neovim/rvveber-nvim

    # concrete
    ./customization.nix
  ];
}
