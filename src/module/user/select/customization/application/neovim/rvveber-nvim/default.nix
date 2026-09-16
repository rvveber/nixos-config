# Installs the rvveber Neovim configuration and its supporting CLI tools.
{pkgs, ...}: {
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
    unzip
    zig
  ];

  xdg.configFile."nvim/lua" = {
    source = ./src/config/lua;
    recursive = true;
  };
}
