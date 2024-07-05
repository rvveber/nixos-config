{
  description = "NixOS configuration";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.home-manager.url = "github:nix-community/home-manager";
  inputs.nixos-hardware.url = "github:NixOS/nixos-hardware/master";

  outputs = { self, nixpkgs, ... }@attrs: {

    nixosConfigurations.cake = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = attrs;
      modules = [
	./host/cake
#	./user/robin/default.nix
	
#	./module/hardware/audio.nix
#	./module/hardware/bluetooth.nix

#	./module/programs/hyprland.nix
      ];
    };

    nixosConfigurations.b1kini = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = attrs;
      modules = [
        ./host/b1kini/default.nix
	./user/i/default.nix
	
	./module/hardware/audio.nix
	./module/hardware/bluetooth.nix

	./module/programs/hyprland.nix
      ];
    };

  };
}

