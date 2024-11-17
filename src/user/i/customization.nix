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
  users.users.i = {
    isNormalUser = true;
    home = "/home/i";
    description = "Robin Weber";
    extraGroups = ["networkmanager" "wheel"];
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
    ];
  };

  # use zsh shell and customize
  imports = [../../module/select/application/shell/zsh];
  users.users.i.shell = pkgs.zsh;

  home-manager.users.i = {
    home.username = "i";
    home.homeDirectory = "/home/i";
    home.stateVersion = "24.05";

    programs = {
      zsh = {
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
            {name = "MichaelAquilina/zsh-you-should-use.git";}
          ];
        };
      };
      yazi.enableZshIntegration = true;
      direnv.enableZshIntegration = true;
    };
  };

  environment.shellAliases = {
    v = "nvim";
    vi = "nvim";
  };

  nixpkgs.config.chromium.enableWideVine = true;
  # TODO: Move to free options exclusively
  nixpkgs.config.allowUnfree = true;
  # TODO: Remove once unnecessary
  nixpkgs.config.permittedInsecurePackages = [
    "electron-27.3.11" # EOL Electron - needed for LogSeq
  ];
  services.greetd.settings.initial_session.user = "i";
}
