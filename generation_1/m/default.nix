{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
	kitty
	chromium
	git
	neovim
  ];

  programs.direnv.enable = true;
}
