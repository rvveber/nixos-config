{ pkgs, ... }:

{
  services = {
    udev.packages = [ pkgs.trezor-udev-rules ];
  };
}