{
  libs,
  pkgs,
  config,
  ...
}: {
  /*
  * libvirtd is a daemon that provides
  * centralized management and control
  * over various virtualization technologies,
  * enabling consistent and unified handling
  * of virtual machines and related resources.
  */
  virtualisation.libvirtd.enable = true;

  /*
  * QEMU is an open-source emulator and virtualizer
  * that enables hardware virtualization,
  * allowing you to run operating systems and applications
  * designed for one architecture on another,
  * or to create and manage virtual machines
  * on the same architecture.
  */
  environment.systemPackages = with pkgs; [
    qemu
  ];
}
