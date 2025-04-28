{
  pkgs,
  ags,
  astal,
  ...
}: let
  rvveber-app-launcher = ags.lib.bundle {
    inherit pkgs;
    src = ./src;
    name = "rvveber-app-launcher";
    entry = "ts/App.ts";
    gtk4 = true;

    # Additional libraries and executables to add to gjs' runtime
    extraPackages = [
      astal.packages.${pkgs.system}.battery
      astal.packages.${pkgs.system}.hyprland
      astal.packages.${pkgs.system}.apps
      astal.packages.${pkgs.system}.io
    ];
  };
in {
  environment.systemPackages = [
    rvveber-app-launcher
  ];
}
