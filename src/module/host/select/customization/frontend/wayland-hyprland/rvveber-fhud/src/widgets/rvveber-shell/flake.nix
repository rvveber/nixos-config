{
  description = "rvveber-shell: Quickshell widget development and UI package";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {nixpkgs, ...}: let
    forAllSystems = nixpkgs.lib.genAttrs ["x86_64-linux" "aarch64-linux"];
  in {
    devShells = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = pkgs.mkShell {
        packages = with pkgs; [
          quickshell
          python3
          qt6.qtdeclarative
          qt6.qtquick3d
          qt6.qtshadertools
        ];

        shellHook = ''
          echo "FHUD Quickshell development environment"
          echo "Run: qs --path qml"
          echo "Format: qmlformat -i qml/**/*.qml"
        '';
      };
    });
  };
}
