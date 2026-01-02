{...}: {
  imports = [
    # abstract
    ../../module/host/add/application/home-manager.nix
    ../../module/host/add/hack/replace-node-with-bun.nix
    ../../module/host/select/application/shell/zsh

    # concrete
    ./customization.nix
  ];
}
