{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../../../../../add/application/neovim.nix
  ];

  # Entry point for the lua configuration
  programs.neovim.initLua = builtins.readFile ./src/config/init.lua;

  # Additional packages for the neovim setup
  home.packages = with pkgs; [
    git
    gnumake
    ripgrep
    cargo
    unzip
    zig
    markdownlint-cli
  ];

  xdg.configFile."nvim/lua" = {
    source = ./src/config/lua;
    recursive = true;
  };

  xdg.configFile."nvim/doc" = {
    source = ./src/config/doc;
    recursive = true;
  };
}
