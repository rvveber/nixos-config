_: {
  # Enable better support using the OpenTabletDriver
  hardware.opentabletdriver.enable = true;

  # Required by the OpenTabletDriver to work properly
  hardware.uinput.enable = true;
  boot.kernelModules = ["uinput"];
}
