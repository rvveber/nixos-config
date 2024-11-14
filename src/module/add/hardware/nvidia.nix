{
  config,
  pkgs,
  ...
}: {
  hardware.graphics = {
    enable = true;
    /*
    extraPackages = with pkgs; [
      vulkan-loader
      vulkan-validation-layers
      vulkan-extension-layer
      vulkan-tools
    ];
    */
  };

  # load nvidea driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = false;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    # production 550.120
    # beta 560.35.03
    # stable 560.35.03
  };
}
