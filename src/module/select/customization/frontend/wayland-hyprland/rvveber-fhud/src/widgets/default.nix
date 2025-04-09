{
  pkgs,
  ags,
  astal,
  ...
}: let
  rvveber-fhud-widgets = ags.lib.bundle {
    inherit pkgs;
    src = ./.;
    name = "rvveber-fhud-widgets";
    entry = "app.ts";
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
    rvveber-fhud-widgets
  ];
}
