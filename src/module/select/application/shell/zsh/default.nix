{
  libs,
  pkgs,
  config,
  home-manager,
  ...
}: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    autosuggestions.enable = true;
  };

  environment.shells = [pkgs.zsh];
}
