# Loads the Realtek RTL8821CU USB Wi-Fi driver during early boot.
{config, ...}: {
  boot.initrd.kernelModules = ["8821cu"];
  boot.extraModulePackages = [config.boot.kernelPackages.rtl8821cu];
}
