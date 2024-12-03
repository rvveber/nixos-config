{
  config,
  pkgs,
  home-manager,
  ...
}: {
  # dependencies
  imports = [
    ../../../../../add/application/home-manager.nix
    ../../../../../add/application/neovim.nix
    ../../../../../add/hack/replace-node-with-bun.nix
  ];

  # nvim plugins need the following packages to be installed
  environment.systemPackages = with pkgs; [
    git
    gnumake
    ripgrep
    unzip
    zig
    nerd-fonts.symbols-only
  ];

  # environment.sessionVariables = {
  #  MYVIMRC = builtins.toString ./src/config/init.lua;
  # };

  # nvim configuration
  home-manager.sharedModules = [
    {
      home.file.".config/nvim" = {
        source = ./src/config;
        recursive = true;
      };
    }
  ];
}
