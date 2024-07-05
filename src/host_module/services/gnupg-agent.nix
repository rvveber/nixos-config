{ config, pkgs, ... }:
{
  services.gnupg-agent = {
    enable = true;
    enableSSHSupport = true;
  };
}
