{
  ags,
  astal,
  pkgs,
}: let
  system = pkgs.stdenv.hostPlatform.system;
  appearance = import ../../appearance.nix;
  palette = import ../../theme.nix;
  alpha = value: builtins.fromTOML ''value = 0x${value}'';
  generatedAppearance = pkgs.writeText "_appearance.scss" ''
    $radius: ${toString appearance.radius}px;
    $border-width: ${toString appearance.borderWidth}px;
    $gap: ${toString appearance.gap}px;
    $inner-glow-range: ${toString appearance.glow.inner.range}px;
    $inner-glow-alpha: ${toString ((alpha appearance.glow.inner.activeAlpha).value / 255.0)};
    $outer-glow-range: ${toString appearance.glow.outer.range}px;
    $outer-glow-alpha: ${toString ((alpha appearance.glow.outer.activeAlpha).value / 255.0)};
    $background: ${palette.base00};
    $surface: ${palette.base01};
    $surface-active: ${palette.base02};
    $muted: ${palette.base04};
    $foreground: ${palette.base05};
    $foreground-strong: ${palette.base07};
    $accent: ${palette.base0C};
    $error: ${palette.base08};
    $warning: ${palette.base0A};
    $success: ${palette.base0B};
  '';
  astalPackages = with astal.packages.${system}; [
    astal4
    io
    hyprland
    battery
    powerprofiles
    wireplumber
    bluetooth
    network
    notifd
    apps
  ];
in
  pkgs.stdenv.mkDerivation {
    pname = "rvveber-fhud-ui";
    version = "0.1.0";
    src = ./.;

    nativeBuildInputs = with pkgs; [
      wrapGAppsHook4
      gobject-introspection
      ags.packages.${system}.default
    ];

    buildInputs =
      astalPackages
      ++ (with pkgs; [
        libadwaita
        libsoup_3
        glib
        gjs
        pango
      ]);

    preFixup = ''
      gappsWrapperArgs+=(--prefix PATH : ${pkgs.lib.makeBinPath [pkgs.brightnessctl]})
    '';

    installPhase = ''
      runHook preInstall

      cp ${generatedAppearance} _appearance.scss

      mkdir -p $out/bin $out/share
      find . -mindepth 1 -maxdepth 1 \
        ! -name result \
        ! -name node_modules \
        -exec cp -R {} $out/share/ \;
      ags bundle app.ts $out/bin/rvveber-fhud-ui -d "SRC='$out/share'"

      runHook postInstall
    '';

    meta = {
      description = "FHUD UI components for Hyprland";
      license = pkgs.lib.licenses.mit;
      platforms = pkgs.lib.platforms.linux;
    };
  }
