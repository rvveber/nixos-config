{...}: {
  imports = [
    # abstract
    ../../module/add/application/home-manager.nix
    ../../module/add/hack/replace-node-with-bun.nix
    ../../module/select/customization/application/neovim/rvveber-nvim

    # concrete
    ./customization.nix
  ];
}
