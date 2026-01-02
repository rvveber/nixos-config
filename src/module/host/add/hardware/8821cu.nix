{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  boot.initrd.kernelModules = ["8821cu"];
  boot.extraModulePackages = [config.boot.kernelPackages.rtl8821cu];
}
