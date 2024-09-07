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
    ripgrep
    unzip
    zig
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
