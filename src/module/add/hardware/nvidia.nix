{
  config,
  pkgs,
  home-manager,
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

  home-manager.sharedModules = [
    {
      wayland.windowManager.hyprland = {
        enable = true;
        systemd.enable = false; # Conflicts with uwsm
        settings = {
          env = [
            "GBM_BACKEND,nvidia-drm"
            "__GLX_VENDOR_LIBRARY_NAME,nvidia"
            "LIBVA_DRIVER_NAME,nvidia"
            "__GL_GSYNC_ALLOWED,1"
            "__GL_VRR_ALLOWED,1"
          ];
        };
      };
    }
  ];
}
