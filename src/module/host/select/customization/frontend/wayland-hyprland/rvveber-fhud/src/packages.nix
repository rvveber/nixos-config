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
