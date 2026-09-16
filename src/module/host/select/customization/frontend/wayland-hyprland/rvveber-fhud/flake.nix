{
  description = "rvveber-fhud: A GPU-accelerated Hyprland shell with Quickshell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    stylix,
    ...
  }: let
    forAllSystems = nixpkgs.lib.genAttrs ["x86_64-linux" "aarch64-linux"];
    makePackages = pkgs:
      import ./src/packages.nix {
        inherit pkgs;
        source = self;
        ui = import ./src/widgets/rvveber-shell/package.nix {inherit pkgs;};
      };
  in {
    packages = forAllSystems (system: makePackages nixpkgs.legacyPackages.${system});

    checks = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      inherit (self.packages.${system}) ui holographic-shader;
      workspace-groups =
        pkgs.runCommand "fhud-workspace-group-checks" {
          nativeBuildInputs = [pkgs.bash pkgs.jq pkgs.python3];
        } ''
          python3 ${./src/scripts}/tests/test_workspace_groups.py -v
          touch $out
        '';
    });

    nixosModules.default = import ./src/nixos-module.nix {
      source = self;
      inherit stylix makePackages;
    };
  };
}
