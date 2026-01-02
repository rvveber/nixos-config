_: {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;
  };

  home.shellAliases = {
    v = "nvim";
    vi = "nvim";
  };
}
