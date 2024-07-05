{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./configuration.nix

    ../../host_module/localization/de_DE.nix
    ../../host_module/hardware/audio.nix
    ../../host_module/hardware/8821cu.nix
  ];
}
