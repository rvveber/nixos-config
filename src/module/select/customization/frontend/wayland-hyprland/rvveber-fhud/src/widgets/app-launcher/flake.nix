{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    astal = {
      url = "github:aylur/astal";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    astal,
  }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};

    nativeBuildInputs = with pkgs; [
      meson
      ninja
      pkg-config
      gobject-introspection
      wrapGAppsHook4
      blueprint-compiler
      dart-sass
      esbuild
    ];

    astalPackages = with astal.packages.${system}; [
      io
      apps
      astal4
      battery
      wireplumber
      network
      mpris
      powerprofiles
      tray
      bluetooth
      hyprland
    ];
  in {
    packages.${system}.default = pkgs.stdenv.mkDerivation {
      name = "rvveber-app-launcher";
      src = ./.;
      inherit nativeBuildInputs;
      buildInputs = astalPackages ++ [pkgs.gjs];
    };

    devShells.${system}.default = pkgs.mkShell {
      packages = nativeBuildInputs ++ astalPackages ++ [pkgs.gjs pkgs.nodejs];
      shellHook = ''
        alias build="meson setup build --wipe --prefix \"$(pwd)/result\" && meson install -C build"
        alias run="./result/bin/app-launcher"
        alias types="npx @ts-for-gir/cli generate --ignoreVersionConflicts || true"
        echo "Aliases defined:"
        echo "  build     (builds the project)"
        echo "  run       (runs the project)"
        echo "  types     (generates TypeScript types)"
      '';
    };
  };
}
