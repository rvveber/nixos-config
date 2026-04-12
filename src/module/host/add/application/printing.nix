{pkgs, ...}: {
  # dependencies
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
