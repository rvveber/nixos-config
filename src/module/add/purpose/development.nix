{
  pkgs,
  config,
  ...
}: {
  programs.direnv.enable = true;
  environment.systemPackages = [
    pkgs.git
    pkgs.gnumake

    pkgs.cachix
    pkgs.devenv

    pkgs.koji # cli tool for conventional commits
    pkgs.git-absorb # https://github.com/tummychow/git-absorb
  ];
  nix.settings = {
    extra-substituters = [
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  # programs.git = {
  #   enable = true;
  #   extraConfig = {
  #     alias."diff-apply" = "!f() { git diff \"$1\"..\"$2\" | git apply; }; f";
  #   };
  # };
}
