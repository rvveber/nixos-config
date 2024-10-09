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
  ];

  # nvim plugins need the following packages to be installed
  environment.systemPackages = with pkgs; [
    git
    gnumake
    ripgrep
    unzip
    zig
    nerdfonts

    # development with typescript
  ];

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
