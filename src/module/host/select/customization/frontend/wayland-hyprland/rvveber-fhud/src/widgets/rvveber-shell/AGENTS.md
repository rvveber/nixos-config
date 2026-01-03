# AGENTS.md - Context for AI Assistants

## Project Overview
This project (`rvveber-fhud`) is a custom shell/HUD for Hyprland on NixOS, built using **AGS (Aylur's Gtk Shell)** and **Astal** (AGS v2 libraries).

## Tech Stack
- **Language:** TypeScript (compiled to GJS - Gnome JavaScript)
- **Framework:** AGS / Astal (GTK4 bindings)
- **State Management:** `gnim` (Signals/State)
- **Build System:** Nix Flakes

## Directory Structure
- `src/widgets/rvveber-shell/`: Root of the UI code.
  - `app.ts`: Main entry point. Starts `TopBar` + `Hud` on the first monitor and handles IPC requests (`requestHandler`).
  - `windows/`: UI Window definitions.
    - `Hud/`: Full-screen app launcher HUD.
    - `TopBar/`: Status bar window (workspace grid, date/time, system modules).
  - `services/`: Shared state and system bindings (audio, battery, bluetooth, brightness, hud, hyprland, network, notifications, power).
  - `style.scss`: Global styles.

## Key Concepts & Gotchas

### 1. State Management (`gnim`)
- We use `createState` for reactive variables.
- Do not `console.log()` state getters or objects returned by `gnim` directly. Their `toString()` can crash (`TypeError: transform is not a function`).
- Always unwrap values before logging (e.g., log strings, not objects).
- `gnim` accessors must be read with `.get()` when you need a boolean/value in logic (e.g., `launcherVisible.get()`); calling the accessor like a function returns another `Accessor` and can make toggles always truthy.

### 2. IPC / Request Handling
- Requests are sent via `ags request "command"`.
- The `requestHandler` in `app.ts` receives these.
- Arguments can arrive comma-separated (e.g., `"request,toggle,launcher"`). `app.ts` strips the `request,` prefix and replaces commas with spaces before matching commands.

### 3. UI Components (Astal/GTK4)
- Uses JSX syntax for GTK widgets.
- `Gtk.EventControllerKey` is used for keyboard input (HUD closes on Escape).
- `Gtk.ScrolledWindow` is used for scrollable areas (not `<scrollable>`).
- The HUD uses `gi://AstalApps` to query and launch applications with fuzzy search.
- **Ellipsizing labels:** Use `Pango.EllipsizeMode` (e.g., `Pango.EllipsizeMode.END`), not `Gtk.EllipsizeMode`.
- **GTK CSS limits:** GTK4 CSS does not support properties like `max-width`; use widget props or layout containers instead.
- **GTK theme colors:** This project uses GTK theme tokens via SCSS variables (e.g., `@theme_fg_color`), combined with `alpha(...)` for transparency. Avoid hard-coded hex colors.
- **SCSS + GTK functions:** `@define-color` is plain CSS and does not mix with Sass. Use Sass variables with `unquote("@theme_*")` and a helper like `gtk-alpha()` that emits `alpha(...)`.

## Debugging
- Logs appear in the terminal where `rvveber-fhud-ui` is running.
- Use `console.log` sparingly and safely.
- To test the launcher toggle:
  ```bash
  src/module/host/select/customization/frontend/wayland-hyprland/rvveber-fhud/src/scripts/app-launcher.sh
  ```

## Networking UI Notes
- `AstalApps.Application.frequency` exists and can be used to sort the initial app list by usage count; switch to `fuzzy_query()` once the user types.
- `AstalNetwork` enums sometimes show as numeric; normalize `primary`/`state` to readable strings for UI.
- `Wifi.deactivate_connection()` expects a callback arg; call with `null` to avoid the “at least 1 argument required” error.
- `Wifi` provides `access_points`, `frequency`, `strength`, and `requires_password` for a usable Wi‑Fi list UI.
- If you use `<For each={...}>`, ensure `For` is imported from `gnim`.
