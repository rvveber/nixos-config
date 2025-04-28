# App Launcher Widget in TypeScript

This example shows you how to create an App Launcher widget using TypeScript+Blueprint+Sass.

## Dependencies

- gjs
- meson
- esbuild
- blueprint-compiler
- sass
- astal4
- astal-apps
- astal-battery
- astal-wireplumber
- astak-network
- astal-mpris
- astak-power-profiles
- astal-tray
- astal-bluetooth
- astal-hyprland

## How to use

> [!NOTE]
> If you are on Nix, there is an example flake included
> otherwise feel free to `rm flake.nix`

- generate types with `ts-for-gir`

    ```sh
    # might take a while
    # also, don't worry about warning and error logs
    npx @ts-for-gir/cli generate --ignoreVersionConflicts
    ```

- developing

    ```sh
    meson setup build --wipe --prefix "$(pwd)/result"
    meson install -C build
    ./result/bin/app-launcher
    ```

- installing

    ```sh
    meson setup build --wipe --prefix /usr
    meson install -C build
    app-launcher
    ```

- adding new typescript files requires no additional steps
- adding new scss files requires no additional steps as long as they are imported from `main.scss`
- adding new ui (blueprint) files will also have to be listed in `meson.build` and in `gresource.xml`

## Features

This app launcher widget allows you to:
- Browse and launch installed desktop applications
- Search for applications by name
- Pin favorite applications for quick access
- Categorize applications by type
