# Enables CUPS printing with mDNS printer discovery.
{pkgs, ...}: {
  imports = [
    ./avahi.nix
  ];

  services.printing = {
    enable = true;
    drivers = with pkgs; [
      cups-filters
      cups-browsed
    ];
  };
}
