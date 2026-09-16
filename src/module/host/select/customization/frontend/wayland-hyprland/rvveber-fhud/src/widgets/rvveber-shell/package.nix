{pkgs}: let
  appearance = import ../../appearance.nix;
  palette = import ../../theme.nix;
  generatedAppearance = pkgs.writeText "Appearance.qml" ''
    pragma Singleton
    import Quickshell
    import QtQuick

    QtObject {
      readonly property int radius: ${toString appearance.radius}
      readonly property int borderWidth: ${toString appearance.borderWidth}
      readonly property int gap: ${toString appearance.gap}
      readonly property int barHeight: ${toString appearance.bar.height}
      readonly property int barSurfaceHeight: ${toString appearance.bar.surfaceHeight}
      readonly property int workspaceSlotWidth: ${toString appearance.workspace.slotWidth}
      readonly property int workspaceLaneHeight: ${toString appearance.workspace.laneHeight}
      readonly property int controlHeight: ${toString appearance.control.height}
      readonly property int rowHeight: ${toString appearance.control.rowHeight}
      readonly property int flyoutWidth: ${toString appearance.flyout.width}
      readonly property int flyoutWideWidth: ${toString appearance.flyout.wideWidth}
      readonly property int flyoutMaximumWidth: ${toString appearance.flyout.maximumWidth}
      readonly property int flyoutListHeight: ${toString appearance.flyout.listHeight}
      readonly property int calendarCellWidth: ${toString appearance.calendar.cellWidth}
      readonly property int calendarCellHeight: ${toString appearance.calendar.cellHeight}
      readonly property int calendarWeekdayHeight: ${toString appearance.calendar.weekdayHeight}
      readonly property int spaceTight: ${toString appearance.space.tight}
      readonly property int spaceCompact: ${toString appearance.space.compact}
      readonly property int spaceRegular: ${toString appearance.space.regular}
      readonly property int spaceRoomy: ${toString appearance.space.roomy}
      readonly property int textLabel: ${toString appearance.text.label}
      readonly property int textTelemetry: ${toString appearance.text.telemetry}
      readonly property int textBody: ${toString appearance.text.body}
      readonly property int textHeading: ${toString appearance.text.heading}
      readonly property int textTitle: ${toString appearance.text.title}
      readonly property int readoutValueWidth: ${toString appearance.readout.valueWidth}
      readonly property int readoutWideValueWidth: ${toString appearance.readout.wideValueWidth}
      readonly property int readoutStatusWidth: ${toString appearance.readout.statusWidth}
      readonly property int readoutWideStatusWidth: ${toString appearance.readout.wideStatusWidth}
      readonly property int ringDiameter: ${toString appearance.ring.diameter}
      readonly property int ringSegments: ${toString appearance.ring.segments}
      readonly property int ringStroke: ${toString appearance.ring.stroke}
      readonly property int ringSweep: ${toString appearance.ring.sweep}
      readonly property int ringGap: ${toString appearance.ring.gap}
      readonly property real opacitySurface: ${toString appearance.opacity.surface}
      readonly property real opacitySubtle: ${toString appearance.opacity.subtle}
      readonly property real opacityQuiet: ${toString appearance.opacity.quiet}
      readonly property real opacityHover: ${toString appearance.opacity.hover}
      readonly property real opacityActive: ${toString appearance.opacity.active}
      readonly property real opacityBorder: ${toString appearance.opacity.border}
      readonly property real opacityFocus: ${toString appearance.opacity.focus}
      readonly property real opacityTrack: ${toString appearance.opacity.track}
      readonly property real opacityList: ${toString appearance.opacity.list}
      readonly property real opacityListActive: ${toString appearance.opacity.listActive}
      readonly property real opacityEntryEcho: ${toString appearance.opacity.entryEcho}
      readonly property bool reducedMotion: Quickshell.env("RVVEBER_FHUD_REDUCED_MOTION") === "1"
      readonly property int motionQuick: reducedMotion ? 0 : ${toString appearance.motion.quick}
      readonly property int motionMove: reducedMotion ? 0 : ${toString appearance.motion.move}
      readonly property int motionScene: reducedMotion ? 0 : ${toString appearance.motion.scene}
      readonly property int motionOrbit: ${toString appearance.motion.orbit}
      readonly property int vectorLineWidth: ${toString appearance.vector.lineWidth}
      readonly property int vectorLength: ${toString appearance.vector.length}
      readonly property color background: "${palette.base00}"
      readonly property color surface: "${palette.base01}"
      readonly property color surfaceActive: "${palette.base02}"
      readonly property color muted: "${palette.base04}"
      readonly property color foreground: "${palette.base05}"
      readonly property color foregroundStrong: "${palette.base07}"
      readonly property color accent: "${palette.base0C}"
      readonly property color error: "${palette.base08}"
      readonly property color warning: "${palette.base0A}"
      readonly property color success: "${palette.base0B}"
      readonly property color healthNormal: "${palette.base0C}"
      readonly property color healthCaution: "${palette.base0A}"
      readonly property color healthCritical: "${palette.base08}"
      readonly property color healthStale: "${palette.base04}"
      readonly property color healthUnknown: "${palette.base04}"
      readonly property string fontFamily: "JetBrains Mono"

      function alpha(color, opacity) {
        return Qt.rgba(color.r, color.g, color.b, opacity)
      }
    }
  '';
  desktopEntry = pkgs.makeDesktopItem {
    name = "org.quickshell";
    desktopName = "FHUD";
    genericName = "Desktop shell";
    exec = "rvveber-fhud-ui";
    noDisplay = true;
    startupWMClass = "org.quickshell";
  };
  runtimePath = pkgs.lib.makeBinPath (with pkgs; [
    bash
    bluez
    brightnessctl
    coreutils
    hyprland
    jq
    networkmanager
    power-profiles-daemon
    systemd
    upower
    uwsm
    wireplumber
  ]);
in
  pkgs.stdenv.mkDerivation {
    pname = "rvveber-fhud-ui";
    version = "0.2.0";
    src = ./.;

    strictDeps = true;
    dontWrapQtApps = true;
    nativeBuildInputs = [
      pkgs.makeWrapper
      pkgs.python3
      pkgs.qt6.qtdeclarative
      pkgs.quickshell
    ];

    postPatch = ''
      cp ${generatedAppearance} qml/Theme/Appearance.qml
    '';

    doCheck = true;
    checkPhase = ''
      runHook preCheck

      qmllint \
        -I ${pkgs.quickshell}/lib/qt-6/qml \
        -I ${pkgs.qt6.qtdeclarative}/lib/qt-6/qml \
        -I ${pkgs.qt6.qtquick3d}/lib/qt-6/qml \
        qml/shell.qml

      python3 -m unittest discover -s tests -v

      runHook postCheck
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/libexec $out/share/rvveber-fhud/Theme $out/share/applications
      cp -R qml/. $out/share/rvveber-fhud/
      cp scripts/power_monitor.py $out/libexec/rvveber-fhud-power-monitor.py
      cp ${desktopEntry}/share/applications/org.quickshell.desktop $out/share/applications/
      makeWrapper ${pkgs.python3}/bin/python3 $out/bin/rvveber-fhud-power-monitor \
        --add-flags "$out/libexec/rvveber-fhud-power-monitor.py"
      makeWrapper ${pkgs.quickshell}/bin/qs $out/bin/rvveber-fhud-ui \
        --add-flags "--path $out/share/rvveber-fhud" \
        --prefix PATH : $out/bin:${runtimePath} \
        --prefix QML2_IMPORT_PATH : ${pkgs.qt6.qtquick3d}/lib/qt-6/qml \
        --prefix XDG_DATA_DIRS : $out/share:${pkgs.quickshell}/share

      runHook postInstall
    '';

    meta = {
      description = "GPU-accelerated FHUD shell for Hyprland, built with Quickshell";
      license = pkgs.lib.licenses.mit;
      platforms = pkgs.lib.platforms.linux;
    };
  }
