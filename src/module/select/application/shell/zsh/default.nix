{
  libs,
  pkgs,
  config,
  ...
}: {
  programs.zsh = {
    enable = true;
  };

  environment.shells = [pkgs.zsh];
  users.defaultUserShell = pkgs.zsh;
}
