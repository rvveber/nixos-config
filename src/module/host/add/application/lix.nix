# Selects Lix as the Nix implementation and retains required compatibility.
{pkgs, ...}: {
  nix = {
    package = pkgs.lixPackageSets.latest.lix;
    settings.extra-deprecated-features = ["or-as-identifier"];
  };
}
