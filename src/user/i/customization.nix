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
    ];
  };

  home-manager.users.i = {
    home.username = "i";
    home.homeDirectory = "/home/i";
    home.stateVersion = "24.05";
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
