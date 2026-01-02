{rvveber-fhud, ...}: {
  # dependencies - foundational modules needed for FHUD
  imports = [
    ../../../../../add/application/home-manager.nix
    ../../../../../add/frontend/wayland-hyprland.nix

    # FHUD UI from flake
    rvveber-fhud.nixosModules.default
  ];
}
