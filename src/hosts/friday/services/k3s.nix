{
  pkgs,
  lib,
  ...
}: let
  k8sDir = ../k8s;

  baseManifests = let
    dir = k8sDir + "/base";
    files = builtins.readDir dir;
    yamlFiles = lib.attrNames (lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".yaml" name) files);
  in
    lib.listToAttrs (map (name: {
        name = "base-${lib.removeSuffix ".yaml" name}";
        value = {source = dir + "/${name}";};
      })
      yamlFiles);

  appsManifests = let
    appsDir = k8sDir + "/apps";
    apps = lib.attrNames (lib.filterAttrs (name: type: type == "directory") (builtins.readDir appsDir));

    getAppManifests = app: let
      appPath = appsDir + "/${app}";
      files = builtins.readDir appPath;
      yamlFiles = lib.attrNames (lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".yaml" name) files);
    in
      lib.listToAttrs (map (name: {
          name = "${app}-${lib.removeSuffix ".yaml" name}";
          value = {source = appPath + "/${name}";};
        })
        yamlFiles);
  in
    lib.foldl' lib.mergeAttrs {} (map getAppManifests apps);
in {
  services.k3s = {
    enable = true;
    role = "server";
    manifests = baseManifests // appsManifests;
  };

  # NixOS links declarative manifests into mutable k3s state. A generation
  # rollback does not remove links introduced by another generation, and their
  # store targets may later disappear. Ignore neither the error nor all mutable
  # state: remove only links whose targets no longer exist before k3s starts.
  systemd.services.k3s.preStart = ''
    if [[ -d /var/lib/rancher/k3s/server/manifests ]]; then
      ${pkgs.findutils}/bin/find /var/lib/rancher/k3s/server/manifests \
        -maxdepth 1 -xtype l -delete
    fi
  '';

  environment.systemPackages = [
    pkgs.kubectl
  ];
}
