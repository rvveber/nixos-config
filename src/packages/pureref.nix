# Packages the PureRef reference image viewer from a version-pinned download.
#
# Why local: PureRef's public download URL ignores the requested version and
# redirects to the latest release, so nixpkgs' hash breaks whenever PureRef
# publishes one. This mirrors nixpkgs' package but fetches from the CDN URL that
# honors the version.
# Remove when: nixpkgs fetches a pinned release
# (https://github.com/NixOS/nixpkgs/pull/590021); then use `pkgs.pureref`.
{
  lib,
  appimageTools,
  makeWrapper,
  runCommand,
  curl,
  gnugrep,
  gnused,
  cacert,
}: let
  pname = "pureref";
  version = "2.1.4";
  homepage = "https://www.pureref.com";
  kindCurl = ''curl -s -A "nixpkgs/Please contact maintainers if there is an issue"'';

  src =
    runCommand "PureRef-${version}.AppImage"
    {
      nativeBuildInputs = [
        curl
        gnugrep
        gnused
        cacert
      ];
      outputHash = "sha256-7HhONcMLT7/Ntn+cG3jyYsIlvp4dRP8YvlvMRNLX+ZU=";
      outputHashMode = "flat";
    }
    ''
      key="$(${kindCurl} "${homepage}/download.php" | grep '%3D%3D' | cut -d '"' -f2)"
      redirect="$(${kindCurl} -o /dev/null -w '%{redirect_url}' "${homepage}/files/build.php?build=LINUX64.Appimage&version=${version}&downloadKey=$key")"
      cdnKey="$(echo "$redirect" | sed 's/.*key=//')"
      ${kindCurl} --fail -L "https://cdn.pureref.dev/build.php?build=LINUX64.Appimage&version=${version}&key=$cdnKey" --output $out
    '';

  archive = appimageTools.extract {inherit pname version src;};
in
  appimageTools.wrapType2 {
    inherit pname version src;

    nativeBuildInputs = [makeWrapper];

    extraInstallCommands = ''
      mv $out/bin/pureref $out/bin/PureRef
      ln -s $out/bin/PureRef $out/bin/pureref
      cp -r ${archive}/usr/share $out
      wrapProgram $out/bin/PureRef \
        --set QT_QPA_PLATFORM xcb \
        --unset QT_STYLE_OVERRIDE \
        --set FONTCONFIG_FILE /etc/fonts/fonts.conf
    '';

    meta = {
      description = "Reference Image Viewer";
      inherit homepage;
      license = lib.licenses.unfree;
      platforms = ["x86_64-linux"];
      mainProgram = "pureref";
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    };
  }
