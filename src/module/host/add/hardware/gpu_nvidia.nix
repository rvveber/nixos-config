# Configures the proprietary NVIDIA driver and its Hyprland environment.
{config, ...}: let
  luaCall = args: {_args = args;};
in {
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
            (luaCall ["GBM_BACKEND" "nvidia-drm"])
            (luaCall ["__GLX_VENDOR_LIBRARY_NAME" "nvidia"])
            (luaCall ["LIBVA_DRIVER_NAME" "nvidia"])
            (luaCall ["__GL_GSYNC_ALLOWED" "1"])
            (luaCall ["__GL_VRR_ALLOWED" "1"])
          ];
        };
      };
    }
  ];
}
