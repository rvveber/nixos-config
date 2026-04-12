{
  config,
  pkgs,
  lib,
  ...
}: let
  username = "rvveber";
  homeDirectory = "/home/rvveber";
in {
  users.users.${username} = {
    isNormalUser = true;
    useDefaultShell = true;
    home = homeDirectory;
    description = "Administrator";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIpto9262U8wsnRbcj/p95fhhrlj7bMqiLmoOfOfnhG0"
    ];
    extraGroups = [
      "wheel"
    ];
  };

  home-manager.users.${username} = {
    config,
    lib,
    osConfig,
    pkgs,
    ...
  }: let
    zshDirectory = "${config.xdg.configHome}/zsh";
  in {
    home = {
      inherit username;
      inherit homeDirectory;

      # The state version is required and should stay at the version you originally installed.
      stateVersion = "26.05";
    };

    programs = {
      zsh = {
        enable = true;
        dotDir = zshDirectory;
        history.size = 1000;
        history.ignoreAllDups = true;
        history.path = "${zshDirectory}/.zsh_history";
        history.ignorePatterns = ["rm *" "pkill *" "cp *"];

        # Disable completion if zsh is enabled system-wide to avoid doubled compinit calls
        enableCompletion =
          if osConfig.programs.zsh.enable
          then !osConfig.programs.zsh.enableCompletion
          else true;
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
    };
  };
}
