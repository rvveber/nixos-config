# Provides one shared, mutable Windows application environment through UMU and
# Proton, independent from Steam shortcuts and compatdata identifiers.
{
  lib,
  pkgs,
  ...
}: let
  # Executables are reported differently across browsers and file managers.
  executableMimeTypes = [
    "application/vnd.microsoft.portable-executable"
    "application/x-ms-dos-executable"
    "application/x-msdownload"
  ];

  # One mutable prefix behaves like a personal Windows installation while UMU
  # supplies Proton's expected Steam Runtime outside the Steam library.
  windows = pkgs.writeShellApplication {
    name = "windows";
    runtimeInputs = [pkgs.coreutils pkgs.umu-launcher];
    text = ''
      # Keep installed applications as user data and allow callers to select a
      # separate prefix when one application needs isolation.
      export WINEPREFIX="''${WINEPREFIX:-''${XDG_DATA_HOME:-$HOME/.local/share}/windows}"
      # A generic ID avoids applying fixes intended for a specific game.
      export GAMEID="''${GAMEID:-umu-default}"
      # GE-Proton is downloaded and updated by UMU for broad application
      # compatibility; callers can override this with a fixed Proton path.
      export PROTONPATH="''${PROTONPATH:-GE-Proton}"
      # The shared environment may run Explorer and installed programs at the
      # same time, so avoid the default wait-for-prefix behavior.
      export PROTON_VERB="''${PROTON_VERB:-run}"

      # Opening the launcher without a file presents the prefix through the
      # familiar Windows Explorer UI.
      if [ "$#" -eq 0 ]; then
        set -- explorer.exe
      elif [ -f "$1" ]; then
        # Installers commonly resolve adjacent payloads from their working
        # directory. Normalize the path before moving there.
        executable="$(realpath "$1")"
        shift
        cd "$(dirname "$executable")"
        set -- "$executable" "$@"
      fi

      exec umu-run "$@"
    '';
  };
  desktopEntry = "windows-environment.desktop";
in {
  home.packages = [windows];

  # The same entry serves the application launcher and executable MIME types:
  # without a file it opens Explorer; with a file it runs that executable.
  xdg.desktopEntries.windows-environment = {
    name = "Windows Environment";
    comment = "Run Windows applications in the shared Proton environment";
    exec = "${lib.getExe windows} %f";
    icon = "wine";
    terminal = false;
    categories = ["Utility"];
    mimeType = executableMimeTypes;
  };

  xdg.mimeApps = {
    enable = true;
    # Register the entry in "Open with" and make double-click installation the
    # default workflow for recognized Windows executables.
    associations.added = lib.genAttrs executableMimeTypes (_: [desktopEntry]);
    defaultApplications = lib.genAttrs executableMimeTypes (_: [desktopEntry]);
  };
}
