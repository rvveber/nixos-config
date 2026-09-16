# Composes the FHUD Hyprland desktop customization and its package set.
{stylix, ...}: let
  source = ./.;
  makePackages = pkgs:
    import ./src/packages.nix {
      inherit pkgs source;
      ui = import ./src/widgets/rvveber-shell/package.nix {inherit pkgs;};
    };
in {
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

    (import ./src/nixos-module.nix {
      inherit makePackages source stylix;
    })
  ];
}
