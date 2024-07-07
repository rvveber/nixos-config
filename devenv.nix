{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: {
  # https://devenv.sh/packages/
  packages = [
    pkgs.statix
    pkgs.alejandra
  ];

  # https://devenv.sh/languages/
  languages.nix.enable = true;

  cachix.enable = false;
}
