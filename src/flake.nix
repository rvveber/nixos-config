# A flake.nix file
# is an attribute set
# with two attributes called
# inputs and outputs
{
  description = "NixOS configuration";

  # The inputs attribute describes the other flakes
  # that you would like to use
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # The outputs attribute is a *function*
  # Nix will go and fetch all the inputs,
  # load up their flake.nix files,
  # and it will call your outputs function
  # with all of their outputs as arguments.
  outputs = inputs @ {nixpkgs, ...}: {
    nixosConfigurations.cake = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = inputs;
      modules = [
        ./hosts/cake
        ./users/i
      ];
    };
    nixosConfigurations.b1kini = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = inputs;
      modules = [
        ./hosts/b1kini
        ./users/i
      ];
    };
    nixosConfigurations.friday = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = inputs;
      modules = [
        ./hosts/friday
        ./users/rvveber
      ];
    };

    devShells.x86_64-linux.default = import ./shell.nix {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    };

    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
  };
}
