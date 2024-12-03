{
  pkgs,
  config,
  ...
}: {
  programs.direnv.enable = true;
  environment.systemPackages = with pkgs; [
    git
    gnumake

    cachix
    devenv

    koji # cli tool for conventional commits
    git-absorb # https://github.com/tummychow/git-absorb

    # glyphs for development
    nerd-fonts.symbols-only
  ];

  nix.extraOptions = ''
    extra-substituters = https://devenv.cachix.org
    extra-trusted-public-keys = devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw= nixpkgs-python.cachix.org-1:hxjI7pFxTyuTHn2NkvWCrAUcNZLNS3ZAvfYNuYifcEU=
  '';
}
