# Place user specific configuration here.
#
# Either if you want to override something a module defines.
# Or if you want to add something quickly, without thinking about how to encapsulate it in a module.
# In addition, you need to define a user specific bare minimum for Home-Manager here.
{
  config,
  pkgs,
  lib,
  ...
}: let
  username = "i";
  homeDirectory = "/home/i";
in {
  ############################
  # nixos config - global

  # TODO: Remove once unnecessary
  nixpkgs.config.permittedInsecurePackages = [
    "dotnet-sdk-6.0.428" # Needed for godot mono...
  ];

  nixpkgs.config.allowUnfree = true;

  ############################
  # nixos config - per user
  users.users.${username} = {
    isNormalUser = true;
    useDefaultShell = true;
    home = homeDirectory;
    description = "Robin Weber";
    extraGroups = ["networkmanager" "wheel" "docker"];
  };

  services.mullvad-vpn = {
    enable = true;
  };

  ############################
  # home-manager config - per user
  home-manager.users.${username} = {
    config,
    lib,
    osConfig,
    pkgs,
    ...
  }: let
    zshDir = "${config.xdg.configHome}/zsh";
  in {
    imports = [
      ../../module/user/select/customization/application/neovim/rvveber-nvim
      ../../module/user/add/hack/codex-to-api.nix
      ../../module/user/add/application/development.nix
      ../../module/user/add/application/devops.nix
    ];

    xdg.enable = true;
    home = {
      inherit username;
      inherit homeDirectory;
      stateVersion = "24.05";
    };
    home.packages = with pkgs; [
      # essentials
      thunderbird
      (chromium.override {enableWideVine = true;})
      yazi
      ausweisapp

      # editing
      gimp # Raster
      inkscape # Vector

      # testing
      vscode
      spotify
      jujutsu
    ];

    programs = {
      zsh = {
        enable = true;
        dotDir = zshDir;
        history.size = 1000;
        history.ignoreAllDups = true;
        history.path = "${zshDir}/.zsh_history";
        history.ignorePatterns = ["rm *" "pkill *" "cp *"];

        # Disable completion if zsh is enabled system-wide to avoid doubled compinit calls
        enableCompletion =
          if osConfig.programs.zsh.enable
          then !osConfig.programs.zsh.enableCompletion
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

        initContent = lib.mkMerge [
          (lib.mkBefore ''
            # direnv wrapper
            (( ''${+commands[direnv]} )) && emulate zsh -c "$(direnv export zsh)"

            # enable instant prompt
            if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
              source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
            fi

            # load p10k config
            test -f ${config.programs.zsh.dotDir}/.p10k.zsh && source ${config.programs.zsh.dotDir}/.p10k.zsh
            source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme

            # direnv wrapper
            (( ''${+commands[direnv]} )) && emulate zsh -c "$(direnv hook zsh)"
          '')
          (lib.mkAfter ''
            # create a zkbd compatible hash;
            # to add other keys to this hash, see: man 5 terminfo
            typeset -g -A key

            key[Home]="''${terminfo[khome]}"
            key[End]="''${terminfo[kend]}"
            key[Insert]="''${terminfo[kich1]}"
            key[Backspace]="''${terminfo[kbs]}"
            key[Delete]="''${terminfo[kdch1]}"
            key[Up]="''${terminfo[kcuu1]}"
            key[Down]="''${terminfo[kcud1]}"
            key[Left]="''${terminfo[kcub1]}"
            key[Right]="''${terminfo[kcuf1]}"
            key[PageUp]="''${terminfo[kpp]}"
            key[PageDown]="''${terminfo[knp]}"
            key[Shift-Tab]="''${terminfo[kcbt]}"
            key[Control-Left]="''${terminfo[kLFT5]}"
            key[Control-Right]="''${terminfo[kRIT5]}"

            autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
            zle -N up-line-or-beginning-search
            zle -N down-line-or-beginning-search

            # setup key accordingly
            [[ -n "''${key[Home]}"          ]] && bindkey -- "''${key[Home]}"       beginning-of-line
            [[ -n "''${key[End]}"           ]] && bindkey -- "''${key[End]}"        end-of-line
            [[ -n "''${key[Insert]}"        ]] && bindkey -- "''${key[Insert]}"     overwrite-mode
            [[ -n "''${key[Backspace]}"     ]] && bindkey -- "''${key[Backspace]}"  backward-delete-char
            [[ -n "''${key[Delete]}"        ]] && bindkey -- "''${key[Delete]}"     delete-char
            [[ -n "''${key[Up]}"            ]] && bindkey -- "''${key[Up]}"         up-line-or-beginning-search
            [[ -n "''${key[Down]}"          ]] && bindkey -- "''${key[Down]}"       down-line-or-beginning-search
            [[ -n "''${key[Left]}"          ]] && bindkey -- "''${key[Left]}"       backward-char
            [[ -n "''${key[Right]}"         ]] && bindkey -- "''${key[Right]}"      forward-char
            [[ -n "''${key[PageUp]}"        ]] && bindkey -- "''${key[PageUp]}"     beginning-of-buffer-or-history
            [[ -n "''${key[PageDown]}"      ]] && bindkey -- "''${key[PageDown]}"   end-of-buffer-or-history
            [[ -n "''${key[Shift-Tab]}"     ]] && bindkey -- "''${key[Shift-Tab]}"  reverse-menu-complete
            [[ -n "''${key[Control-Left]}"  ]] && bindkey -- "''${key[Control-Left]}"  backward-word
            [[ -n "''${key[Control-Right]}" ]] && bindkey -- "''${key[Control-Right]}" forward-word


            # Finally, make sure the terminal is in application mode, when zle is
            # active. Only then are the values from $terminfo valid.
            if (( ''${+terminfo[smkx]} && ''${+terminfo[rmkx]} )); then
                    autoload -Uz add-zle-hook-widget
                    function zle_application_mode_start { echoti smkx }
                    function zle_application_mode_stop { echoti rmkx }
                    add-zle-hook-widget -Uz zle-line-init zle_application_mode_start
                    add-zle-hook-widget -Uz zle-line-finish zle_application_mode_stop
            fi

            # Makes esc delay for vim mode shorter
            export KEYTIMEOUT=5


          '')
        ];
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
  };
}
