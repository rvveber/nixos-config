{ pkgs, ... }:

{
  imports = [
	./hardware-configuration.nix
	./configuration.nix
	./system/default.nix
	./user/robin/default.nix
  ];
}
