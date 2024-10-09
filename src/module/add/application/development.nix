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

    nerdfonts # glyphs for development
  ];

  nix.settings = {
    extra-substituters = [
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

}
