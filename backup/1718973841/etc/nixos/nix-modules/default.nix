{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
	kitty
	chromium
	git
	neovim
  ];

  programs.direnv.enable = true;
  #programs.zsh.enable = true;
  
  #users.defaultUserShell = pkgs.zsh;

  environment.sessionVariables.DEFAULT_BROWSER = "${pkgs.chromium}/bin/chromium";
}
