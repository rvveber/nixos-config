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
    pkgs.nixd
    pkgs.nil
    pkgs.nix-doc
    pkgs.brightnessctl
  ];

  # https://devenv.sh/languages/
  languages.nix.enable = true;

  cachix.enable = false;
}
