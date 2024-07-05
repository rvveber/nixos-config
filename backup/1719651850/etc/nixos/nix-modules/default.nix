{ pkgs, ... }:

{

  imports = [
    ./audio.nix
    ./8821cu.nix
    ./bluetooth.nix
    ./hibernate.nix
    ./hyprland.nix
    ./chromium.nix
    ./packages.nix
    ./nvidia.nix
    ./services.nix
    ./trezor.nix
  ];

  environment.systemPackages = with pkgs; [
	kitty
	chromium
	git
	neovim
  ];

  programs.direnv.enable = true;
  environment.sessionVariables.DEFAULT_BROWSER = "${pkgs.chromium}/bin/chromium";
}
