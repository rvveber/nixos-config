{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    ags = {
      url = "github:aylur/ags";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    ags,
  }: let
    system = "x86_64-linux";
    rvveberFhudWidgets = import ./default.nix {inherit ags;};
  in {
    # Make the package available
    packages.${system}.default = rvveberFhudWidgets;

    # Define the development environment
    devShells.${system}.default = ags.pkgs.mkShell {
      buildInputs = [
        ags.pkgs.gjs
        ags.pkgs.gtk4-layer-shell
        ags.pkgs.wayland
        ags.packages.${system}.default
      ];

      shellHook = ''
        echo "Welcome to the development environment for rvveber-fhud-widgets!"
        echo "You can run the project using:"
        echo "ags run --gtk4 -d ."
      '';
    };
  };
}
