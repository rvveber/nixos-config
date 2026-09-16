# rvveber-shell

FHUD is a Quickshell 0.3 desktop shell for Hyprland. Its QML entry point is
`qml/shell.qml`; the Nix package generates `Theme/Appearance.qml` from the
toolkit-neutral appearance and Base16 values owned by the parent module.
Visual and interaction work follows the
[FutureHUD style guide](../../../docs/future-hud-styleguide.md).

## Boundaries

- `Services/` owns reactive system state and shell IPC.
- `Components/` owns reusable geometry and interaction primitives.
- `TopBar/` owns the exclusive panel and anchored flyouts.
- `Hud/` owns launcher, clipboard, and future-HUD scenes.
- `Assets/` contains visual inputs consumed by QML scenes.

Prefer native Quickshell services when they expose the required domain. Use a
small process-backed service for NetworkManager, BlueZ, brightness, or an
existing FHUD helper when Quickshell has no equivalent API.

All FHUD surfaces consume `Appearance`; local color and radius constants break
the shared appearance chain. Top-bar flyouts are custom `PopupWindow`
surfaces so toolkit decoration never introduces a second corner vocabulary.

Run development and validation through the containing Nix flake. The packaged
entry point is `rvveber-fhud-ui`; external callers use `ipc call hud`.
