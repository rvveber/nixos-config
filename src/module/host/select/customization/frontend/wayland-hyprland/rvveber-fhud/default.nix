{rvveber-fhud, ...}: {
  # dependencies - foundational modules needed for FHUD
  imports = [
    # Compatibility shim: newer nixpkgs variants can drop this option while
    # external modules still reference it.
    ({lib, ...}: {
      options.services.displayManager.generic = lib.mkOption {
        type = lib.types.submodule {
          freeformType = lib.types.attrsOf lib.types.anything;
        };
        default = {};
        description = "Compatibility option for modules referencing services.displayManager.generic.";
      };
    })

    ../../../../../add/application/home-manager.nix
    ../../../../../add/frontend/wayland-hyprland.nix

    # FHUD UI from flake
    rvveber-fhud.nixosModules.default
  ];
}
