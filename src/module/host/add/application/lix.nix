{pkgs, ...}: {
  nix = {
    package = pkgs.lixPackageSets.latest.lix;
    settings.extra-deprecated-features = ["or-as-identifier"];
  };
}
