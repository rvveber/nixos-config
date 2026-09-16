# Enables libvirt and installs QEMU for local virtual machines.
{pkgs, ...}: {
  virtualisation.libvirtd.enable = true;

  environment.systemPackages = with pkgs; [
    qemu
  ];
}
