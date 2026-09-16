# Builds an inventory fixture with links to mutable and unrelated store paths.
{pkgs}: let
  outside = pkgs.runCommand "outside-closure" {} ''
    mkdir -p "$out/node_modules/outside-closure"
    echo '{"name":"outside-closure","version":"9.9.9"}' > "$out/node_modules/outside-closure/package.json"
  '';
in
  pkgs.runCommand "periodic-security-scan-fixture" {} ''
    mkdir -p "$out/node_modules/inside-closure"
    echo '{"name":"inside-closure","version":"1.0.0"}' > "$out/node_modules/inside-closure/package.json"
    ln -s /tmp "$out/mutable"
    ln -s ${outside} "$out/outside"
    ln -s ../.. "$out/node_modules/inside-closure/cycle"
  ''
