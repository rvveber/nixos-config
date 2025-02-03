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
  # nixos config - global
  nixpkgs.config.chromium.enableWideVine = true;
  # TODO: Move to free options exclusively
  nixpkgs.config.allowUnfree = true;
  # TODO: Remove once unnecessary
  nixpkgs.config.permittedInsecurePackages = [
    "electron-27.3.11" # EOL Electron - needed for LogSeq
    "dotnet-sdk-6.0.428" # Needed for godot mono...
  ];
  services.mullvad-vpn = {
    enable = true;
  };

  ############################
  # nixos config - per user
  users.users.i = {
    isNormalUser = true;
    useDefaultShell = true;
    home = "/home/i";
    description = "Robin Weber";
    extraGroups = ["networkmanager" "wheel" "docker"];
    packages = with pkgs; [
      # essentials
      thunderbird
      chromium
      yazi

      # editing
      gimp #Raster
      inkscape #Vector
      tenacity #Audio
      blender #3D

      # devops
      k3sup
      mullvad-vpn
      kubernetes-helm
      kubectl
      helm-docs

      # testing
      spotify
      vscode
      logseq
    ];
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
      history.size = 1000;
      history.ignoreAllDups = true;
      history.path = "$XDG_CONFIG_HOME/zsh/.zsh_history";
      history.ignorePatterns = ["rm *" "pkill *" "cp *"];

      # Disable completion if zsh is enabled system-wide to avoid doubled compinit calls
      enableCompletion =
        if config.programs.zsh.enable
        then !config.programs.zsh.enableCompletion
        else true;
      # For debugging load-times
      zprof.enable = false;

      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      plugins = [
        {
          name = pkgs.zsh-nix-shell.pname;
          inherit (pkgs.zsh-nix-shell) src;
        }
        {
          name = pkgs.zsh-z.pname;
          inherit (pkgs.zsh-z) src;
        }
        {
          name = pkgs.zsh-autopair.pname;
          inherit (pkgs.zsh-autopair) src;
        }
        {
          name = pkgs.zsh-powerlevel10k.pname;
          inherit (pkgs.zsh-powerlevel10k) src;
        }
      ];

      initExtraFirst = ''
        (( ''${+commands[direnv]} )) && emulate zsh -c "$(direnv export zsh)"

        # enable instant prompt
        if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi
        test -f ~/${config.home-manager.users.i.programs.zsh.dotDir}/.p10k.zsh && source ~/${config.home-manager.users.i.programs.zsh.dotDir}/.p10k.zsh
        source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme

        (( ''${+commands[direnv]} )) && emulate zsh -c "$(direnv hook zsh)"
      '';

      # Default NixOS configuration overrides keybinds for up and down arrow keys.
      initExtra = ''
        bindkey "''${key[Up]}" up-line-or-search

        mullvad connect
      '';
    };
    yazi = {
      enable = true;
      enableZshIntegration = true;
    };
    direnv = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
