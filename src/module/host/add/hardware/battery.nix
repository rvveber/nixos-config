{
  config,
  lib,
  ...
}: {
  # Essential power/battery services for laptops.
  powerManagement.enable = lib.mkDefault true;
  services.upower.enable = lib.mkDefault true;
  services.power-profiles-daemon.enable = lib.mkDefault true;
}
