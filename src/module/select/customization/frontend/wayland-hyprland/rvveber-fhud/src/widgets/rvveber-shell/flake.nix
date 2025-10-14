{
  description = "rvveber-shell: AGS/Astal widget development and UI package";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    astal = {
      url = "github:aylur/astal";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ags = {
      url = "github:aylur/ags";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.astal.follows = "astal";
    };
  };

  outputs = {
    nixpkgs,
    astal,
    ags,
    ...
  }: let
    forAllSystems = nixpkgs.lib.genAttrs ["x86_64-linux" "aarch64-linux"];
  in {
    packages = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      pname = "rvveber-fhud-ui";
      entry = "app.ts";

      # All astal packages needed for the widgets
      astalPackages = with astal.packages.${system}; [
        astal4
        io
        hyprland
        battery
        wireplumber
        bluetooth
        network
        notifd
        apps
      ];

      extraPackages =
        astalPackages
        ++ [
          pkgs.libadwaita
          pkgs.libsoup_3
        ];
    in {
      default = pkgs.stdenv.mkDerivation {
        inherit pname;
        version = "0.1.0";
        src = ./.;

        nativeBuildInputs = with pkgs; [
          wrapGAppsHook4 # Use GTK4 version for astal4
          gobject-introspection
          ags.packages.${system}.default
        ];

        buildInputs = extraPackages ++ (with pkgs; [
          glib
          gjs
        ]);

        preFixup = ''
          gappsWrapperArgs+=(
            --prefix PATH : ${pkgs.lib.makeBinPath [
              pkgs.brightnessctl
            ]}
          )
        '';

        installPhase = ''
          runHook preInstall

          mkdir -p $out/bin
          mkdir -p $out/share
          cp -r * $out/share
          ags bundle ${entry} $out/bin/${pname} -d "SRC='$out/share'"

          runHook postInstall
        '';

        meta = with pkgs.lib; {
          description = "FHUD UI Components for Hyprland";
          platforms = platforms.linux;
        };
      };
    });

    devShells = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};

      # All astal packages needed for the widgets
      astalPackages = with astal.packages.${system}; [
        astal4
        io
        hyprland
        battery
        wireplumber
        bluetooth
        network
        notifd
        apps
      ];

      extraPackages =
        astalPackages
        ++ [
          pkgs.libadwaita
          pkgs.libsoup_3
        ];
    in {
      default = pkgs.mkShell {
        buildInputs = [
          (ags.packages.${system}.default.override {
            inherit extraPackages;
          })
          pkgs.brightnessctl
          pkgs.nodejs
          pkgs.typescript
          pkgs.sass
          pkgs.gobject-introspection
        ] ++ astalPackages;

        shellHook = ''
          echo "🎨 rvveber-shell development environment"
          echo "Run: ags types -d . -u  (to generate/update TypeScript types)"
          echo "Run: ags run app.ts     (to test the widgets)"
          echo ""
        '';
      };
    });
  };
}
