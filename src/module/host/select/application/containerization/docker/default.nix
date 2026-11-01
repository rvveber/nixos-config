# Selects rootless Docker with pass-backed registry credential support. The
# daemon runs as the user, so Docker access does not grant root on the host.
{pkgs, ...}: {
  imports = [
    ../../../../add/application/containerization.nix
    ../../../../add/application/credential-store.nix
  ];

  environment.systemPackages = [pkgs.docker-credential-helpers];

  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };
}
