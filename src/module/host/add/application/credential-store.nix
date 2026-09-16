# Installs pass as the credential backend used by container CLI helpers.
{pkgs, ...}: {
  environment.systemPackages = [pkgs.pass];
}
