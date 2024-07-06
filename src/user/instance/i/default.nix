# src/user/$username/default.nix - user specific configuration
{ config, pkgs, home-manager, ... }:


{
  users.users.i = {
    isNormalUser = true;
    description = "Robin Weber";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      thunderbird
    ];
  };

#  imports = [
#    home-manager.nixosModules.default {
#      home-manager.users.i = import ./home.nix;
#    }
#  ];
}
