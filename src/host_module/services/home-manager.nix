{ config, pkgs, home-manager, ... }:

{
  imports = [
    home-manager.nixosModules.default {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "bak";
    }
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
