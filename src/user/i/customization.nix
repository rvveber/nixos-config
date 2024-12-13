# Place user specific configuration here.
#
# Either if you want to override something a module defines.
# Or if you want to add something quickly, without thinking about how to encapsulate it in a module.
# In addition, you need to define a user specific bare minimum for Home-Manager here.
{
  config,
  pkgs,
  home-manager,
  ...
}: {
  ############################
  # nixos config - per user
  users.users.i = {
    isNormalUser = true;
    home = "/home/i";
    description = "Robin Weber";
    extraGroups = ["networkmanager" "wheel" "docker"];
    packages = with pkgs; [
      thunderbird
      spotify
      vscode
      chromium
      logseq
      inkscape
      yazi

      k3sup
      kubernetes-helm
      kubectl
      helm-docs

      insomnia
    ];
    shell = pkgs.zsh;
  };

  nixpkgs.config.chromium.enableWideVine = true;
  # TODO: Move to free options exclusively
  nixpkgs.config.allowUnfree = true;
  # TODO: Remove once unnecessary
  nixpkgs.config.permittedInsecurePackages = [
    "electron-27.3.11" # EOL Electron - needed for LogSeq
  ];

  environment.shellAliases = {
    v = "nvim";
    vi = "nvim";
  };

  ############################
  # home-manager config - per user
  home-manager.users.i.home = {
    username = "i";
    homeDirectory = "/home/i";
    stateVersion = "24.05";
  };

  home-manager.users.i.programs = {
    zsh = {
      enable = true;
      dotDir = ".config/zsh";
      enableCompletion = true;
      syntaxHighlighting.enable = true;
      zplug = {
        enable = true;
        plugins = [
          {name = "zsh-users/zsh-autosuggestions";}
          {
            name = "romkatv/powerlevel10k";
            tags = ["as:theme" "depth:1"];
          }
          {
            name = "plugins/git";
            tags = ["from:oh-my-zsh"];
          }
          {
            name = "zsh-users/zsh-syntax-highlighting";
            tags = ["defer:2"];
          }
          {name = "MichaelAquilina/zsh-you-should-use";}
        ];
      };
      initExtraFirst = ''
        (( ''${+commands[direnv]} )) && emulate zsh -c "$(direnv export zsh)"

        # enable instant prompt
        if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi
        test -f ~/.config/zsh/.p10k.zsh && source ~/.config/zsh/.p10k.zsh
        source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme

        (( ''${+commands[direnv]} )) && emulate zsh -c "$(direnv hook zsh)"
      '';
    };
    yazi.enableZshIntegration = true;
    direnv.enableZshIntegration = true;
  };
}
