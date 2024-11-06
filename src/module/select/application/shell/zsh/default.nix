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
    autosuggestions = {
      enable = true;
      strategy = ["completion"];
    };
    syntaxHighlighting.enable = true;
  };

  environment.shells = [pkgs.zsh];
}
