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
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
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
    astal = {
      url = "github:aylur/astal";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ags = {
      url = "github:aylur/ags";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.astal.follows = "astal";
    };
  };

  # The outputs attribute is a *function*
  # Nix will go and fetch all the inputs,
  # load up their flake.nix files,
  # and it will call your outputs function
  # with all of their outputs as arguments.
  outputs = {
    self,
    nixpkgs,
    ...
  } @ attrs: {
    nixosConfigurations.cake = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = attrs;
      modules = [
        ./host/cake
        ./user/i
      ];
    };
    nixosConfigurations.b1kini = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = attrs;
      modules = [
        ./host/b1kini
        ./user/i
      ];
    };
    nixosConfigurations.mystery = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = attrs;
      modules = [
        ./host/mystery
      ];
    };
  };
}
