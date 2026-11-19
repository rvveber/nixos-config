# Packages the FutureHUD shell, shader plugin and desktop tools.
{
  pkgs,
  source,
  ui,
}: let
  makeScript = name: runtimeInputs:
    pkgs.writeShellApplication {
      name = "rvveber-fhud-${name}";
      inherit runtimeInputs;
      text = ''
        exec ${pkgs.bash}/bin/bash ${source}/src/scripts/${name}.sh "$@"
      '';
    };
in rec {
  # Why patched: the FHUD shaders sample neighboring texels, so upstream
  # darkwindow's damage tracking leaves stale edges; the damage patch widens
  # damage around shaded windows and renames the plugin's `State` struct, which
  # collides with Hyprland's `State` namespace. The rectangles patch feeds the
  # fhud-debug shader with surface rectangle bounds.
  # Remove when: upstream darkwindow expands damage for shaders that sample
  # neighbors, no longer collides with Hyprland's `State`, and exposes surface
  # rectangles to shaders; the debug overlay depends on the last one.
  holographic-plugin = pkgs.hyprlandPlugins.hypr-darkwindow.overrideAttrs (old: {
    patches = (old.patches or []) ++ [./patches/darkwindow-damage.patch ./patches/darkwindow-rectangles.patch];
    postPatch =
      (old.postPatch or "")
      + ''
        cp ${./rectangles}/* src/
        substituteInPlace Makefile --replace-fail 'CXXFLAGS = -fPIC' 'CXXFLAGS = -O2 -fPIC'
        substituteInPlace src/ShadeManager.cpp \
          --replace-fail '@fhudDamageRadius@' '${toString (17 + (import ./appearance.nix).window.edgeDepth)}'
        substituteInPlace src/CustomShader.cpp \
          --replace-fail 'replaceIdentifier(pixelGetter, "v_TexCoord", "texCoord");' \
            'replaceIdentifier(pixelGetter, "v_texcoord", "texCoord");'
      '';
  });
  holographic-shader = import ./shaders {inherit pkgs;};
  inherit ui;
  default = ui;

  take-screenshot = makeScript "take-screenshot" (with pkgs; [
    grim
    slurp
    hyprland
    hyprpicker
    procps
    jq
    satty
    wl-clipboard
    xdg-user-dirs
    libavif
  ]);

  lock-and-suspend = makeScript "lock-and-suspend" (with pkgs; [
    hyprlock
    systemd
    hyprland
    procps
  ]);

  paste-timestamp = makeScript "paste-timestamp" [pkgs.wl-clipboard];
  handle-monitor-change = makeScript "handle-monitor-change" (with pkgs; [
    coreutils
    hyprland
    jq
    socat
  ]);
  switch-workspace-group = makeScript "switch-workspace-group" [pkgs.hyprland pkgs.jq];
  move-to-workspace-group = makeScript "move-to-workspace-group" [pkgs.hyprland pkgs.jq];
  move-window = makeScript "move-window" [pkgs.hyprland pkgs.jq];
  focus-window = makeScript "focus-window" [pkgs.hyprland pkgs.jq];
  app-launcher = makeScript "app-launcher" [ui focus-window];
  clipboard-owner = makeScript "clipboard-owner" [pkgs.wl-clipboard];
  clipboard = makeScript "clipboard" (with pkgs; [
    cliphist
    coreutils
    file
    hyprland
    imagemagick
    jq
    systemd
    wl-clipboard
  ]);

  nightshift-tuner = pkgs.writeShellApplication {
    name = "rvveber-fhud-nightshift-tuner";
    runtimeInputs = [
      pkgs.hyprshade
      (pkgs.python3.withPackages (python: [python.tkinter]))
    ];
    text = ''
      exec python3 ${source}/src/scripts/nightshift-tuner.py "$@"
    '';
  };
}
