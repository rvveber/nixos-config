# Provides pass as the credential backend shared by container CLI helpers.
{pkgs, ...}: {
  environment.systemPackages = [pkgs.pass];
}
