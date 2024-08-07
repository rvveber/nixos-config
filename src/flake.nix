{
  description = "NixOS configuration";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  inputs.home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.stylix = {
    url = "github:danth/stylix";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.home-manager.follows = "home-manager";
  };
  inputs.hyprlock.url = "git+https://github.com/hyprwm/Hyprlock?submodules=1";

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
  };
}
