{ nixos-hardware, ... }:

{
  imports = [
  	nixos-hardware.nixosModules.tuxedo-pulse-14-gen3
	./hardware-configuration.nix
	./configuration.nix
  ];
}
