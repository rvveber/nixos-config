{ nixos-hardware, ... }:

{
  imports = [
  	nixos-hardware.nixosModules.tuxedo-pulse-14-gen3
		./hardware-configuration.nix
		./configuration.nix

		../../host_module/localization/de_DE.nix
		../../host_module/hardware/audio.nix
		../../host_module/services/home-manager.nix
		../../host_module/services/gnupg-agent.nix
  ];
}
