{
  libs,
  pkgs,
  config,
  ...
}: {
  programs.zsh.enable = true;

  environment.shells = [pkgs.zsh];
  users.defaultUserShell = pkgs.zsh;

  # Prevent the new user dialog in zsh
  system.userActivationScripts.zshrc = "touch .zshrc";
}
