{
  description = "NixOS configuration";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";
  inputs.nixpkgs-unstable.url = "nixpkgs/nixpkgs-unstable";
  inputs.home-manager.url = "github:nix-community/home-manager";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { nixpkgs, home-manager, ... }@attrs: {

    nixosConfigurations.machine = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = attrs;
      modules = [ 
        ./configuration.nix 
	./nix-modules/hibernate.nix
	./nix-modules/default.nix
        ./nix-modules/8821cu.nix
        ./nix-modules/audio.nix
        ./nix-modules/bluetooth.nix
        ./nix-modules/lsp.nix
        ./nix-modules/nvidia.nix
        ./nix-modules/trezor.nix
	./nix-modules/hyprland.nix
	home-manager.nixosModules.home-manager {
	  home-manager.useGlobalPkgs = true;
	  home-manager.useUserPackages = true;
	  home-manager.backupFileExtension = "bak"; 
	  home-manager.users.robin = import ./home.nix;
	}
      ];
    };

  };
}

