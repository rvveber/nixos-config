# Enables Neovim as the default editor with conventional command aliases.
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
