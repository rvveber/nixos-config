# App Launcher für Astal

Dies ist ein App Launcher für Astal, der es ermöglicht, Desktop-Anwendungen einfach zu starten.

## Abhängigkeiten

- gjs
- meson
- esbuild
- blueprint-compiler
- sass
- astal4
- astal-battery
- astal-wireplumber
- astak-network
- astal-mpris
- astak-power-profiles
- astal-tray
- astal-bluetooth
- astal-hyprland

## Funktionen

- Suche nach installierten Desktop-Anwendungen
- Kategoriefilterung
- Anzeige von App-Icons und Namen
- Starten von Anwendungen mit einem Klick

## Verwendung

> [!HINWEIS]
> Wenn du Nix verwendest, ist ein Beispiel-Flake enthalten.
> Andernfalls kannst du einfach `rm flake.nix` ausführen.

- Typen mit `ts-for-gir` generieren

    ```sh
    # Dies kann eine Weile dauern
    # Keine Sorge wegen Warnungen und Fehlern in den Logs
    npx @ts-for-gir/cli generate --ignoreVersionConflicts
    ```

- Entwicklung

    ```sh
    meson setup build --wipe --prefix "$(pwd)/result"
    meson install -C build
    ./result/bin/app-launcher
    ```

- Installation

    ```sh
    meson setup build --wipe --prefix /usr
    meson install -C build
    app-launcher
    ```

- Das Hinzufügen neuer TypeScript-Dateien erfordert keine zusätzlichen Schritte
- Das Hinzufügen neuer SCSS-Dateien erfordert keine zusätzlichen Schritte, solange sie aus `main.scss` importiert werden
- Das Hinzufügen neuer UI-Dateien (Blueprint) muss ebenfalls in `meson.build` und in `gresource.xml` aufgelistet werden
