{ config, pkgs, ... }:

{
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.support32Bit = true;

  users.users.robin.extraGroups = [ "audio" ];
}

