{pkgs, ...}: {
  programs.direnv.enable = true;

  programs.git = {
    enable = true;
    lfs.enable = true;
  };

  home.packages = with pkgs; [
    gnumake
    cachix
    devenv
    koji # cli tool for conventional commits
    git-absorb # https://github.com/tummychow/git-absorb
    nerd-fonts.symbols-only
  ];
}
