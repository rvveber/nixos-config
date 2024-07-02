{ home-manager, ... }:

{

  imports = [
  	./nixos/modules/default.nix
  	home-manager.nixosModules.default {
		home-manager.useGlobalPkgs = true;
		home-manager.useUserPackages = true;
		home-manager.backupFileExtension = "bak";
		home-manager.users.robin = import ./home.nix;
	}
  ];

}
