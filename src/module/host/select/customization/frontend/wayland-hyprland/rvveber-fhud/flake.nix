{
  description = "rvveber-fhud: A modern Hyprland shell with AGS widgets";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    astal = {
      url = "github:aylur/astal";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ags = {
      url = "github:aylur/ags";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.astal.follows = "astal";
    };

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    ags,
    astal,
    stylix,
    ...
  }: let
    forAllSystems = nixpkgs.lib.genAttrs ["x86_64-linux" "aarch64-linux"];
  in {
    packages = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in
      import ./src/packages.nix {
        inherit pkgs;
        source = self;
        ui = import ./src/widgets/rvveber-shell/package.nix {
          inherit ags astal pkgs;
        };
      });

    nixosModules.default = import ./src/nixos-module.nix {
      source = self;
      inherit stylix;
      makePackages = pkgs: self.packages.${pkgs.stdenv.hostPlatform.system};
    };
  };
}
