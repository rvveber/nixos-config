{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    astal = {
      url = "github:aylur/astal";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ags = {
      url = "github:aylur/ags";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    ags,
    astal,
  }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    rvveberFhudWidgets = import ./default.nix {inherit pkgs ags astal;};
  in {
    # Make the package available
    packages.${system}.default = rvveberFhudWidgets;

    # Define the development environment
    devShells.${system}.default = pkgs.mkShell {
      buildInputs = [
        ags.packages.${system}.default
        astal.packages.${system}.default
        # unsure if necessary, to develop
        astal.packages.${system}.battery
        astal.packages.${system}.hyprland
        astal.packages.${system}.apps
        astal.packages.${system}.io
      ];

      shellHook = ''
        echo "Welcome to the development environment for rvveber-fhud-widgets!"
        echo "You can run the project using:"
        echo "ags run --gtk4 -d ."
      '';
    };
  };
}
