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

  environment.systemPackages = [
    pkgs.kubectl
  ];
}
