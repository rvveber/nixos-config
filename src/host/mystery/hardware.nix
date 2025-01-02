{disko, ...}: {
  imports = [
    disko.nixosModules.disko
    ./disko-config.nix
  ];
  disko.devices.disk.main.device = "/dev/vda";
}
