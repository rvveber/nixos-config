{
  config,
  pkgs,
  ...
}: {
  nix.settings.experimental-features = ["nix-command" "flakes"];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_zen;

  boot.initrd.luks.devices."luks-71cfbe03-2af1-4e86-b2f9-9e4ca147568b".device = "/dev/disk/by-uuid/71cfbe03-2af1-4e86-b2f9-9e4ca147568b";
  networking.hostName = "cake";
  networking.networkmanager.enable = true;

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    neovim
    vscode
    chromium
  ];

  system.stateVersion = "24.05";
}
