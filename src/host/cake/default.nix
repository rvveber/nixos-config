{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./configuration.nix

    ../../host_module/hardware/audio.nix
    ../../host_module/hardware/8821cu.nix
    ../../host_module/hardware/nvidia.nix

    ../../host_module/localization/de_DE.nix

    ../../host_module/services/home-manager.nix
    
    ../../host_module/misc/gaming.nix
  ];
}
