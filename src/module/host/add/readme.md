All files in `module/host/add` are NixOS (system) modules.

Import them from:
- `hosts/<host>/default.nix` (host composition), and/or
- `users/<user>/default.nix` (user composition; still a NixOS module in this repo)

Note: even when imported from `users/<user>/default.nix`, these modules still configure the system (not a per-user profile). For per-user services/files/settings, use `module/user/*` modules instead.

Home Manager still installs via Nix (in `/nix/store`), but applies configuration per-user when you use `home-manager.users.<name>.*` (or globally for all HM users via `home-manager.sharedModules`).

Some "applications" must stay system-wide (e.g. `steam`, `appimage` binfmt, daemons, kernel/hardware).
