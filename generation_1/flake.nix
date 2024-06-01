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
	./m/hibernate.nix
	./m/default.nix
        ./m/8821cu.nix
        ./m/audio.nix
        ./m/bluetooth.nix
        ./m/hyprland.nix
        ./m/lsp.nix
        ./m/nvidia.nix
        ./m/trezor.nix
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

