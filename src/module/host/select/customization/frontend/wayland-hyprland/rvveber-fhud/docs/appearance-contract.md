# Appearance contract

FHUD needs one vocabulary for compositor decoration and shell surfaces. Stylix
already owns the portable parts of that vocabulary: palette, typography,
opacity, icons, cursor, and wallpaper. Geometry remains an FHUD concern until a
portable upstream model exists.

Stylix has an open proposal for border radius and related border/spacing values:
[nix-community/stylix#886](https://github.com/nix-community/stylix/issues/886).
The maintainers identify the same boundary: many targets cannot represent these
values consistently, and inner versus outer radii have different semantics.

GTK CSS and Qt Style Sheets both support `border-radius`, padding, and margins,
but neither toolkit exports a shared desktop design-token registry. A GTK named
color or custom CSS value is invisible to Qt, and a Qt palette or QSS value is
invisible to GTK. Applications using libadwaita or custom Qt Quick controls may
also constrain or replace toolkit themes. Treating either toolkit as the source
would therefore create an adapter-shaped global variable without global
consumers.

## Project idea: desktop appearance adapter

Keep a small toolkit-neutral Nix value set and generate target-native output.
The adapter should remain useful outside Hyprland and Quickshell.

Owned tokens:

- one window and surface radius;
- border width;
- compositor gutter;
- compact spacing scale;
- inner glare and outer focus-glow geometry;
- semantic colors sourced from `config.lib.stylix.colors` or the configured
  Base16 scheme;
- typography sourced from Stylix.

Target adapters:

- Hyprland decoration, gaps, border, glow, and shadow values;
- a generated Quickshell QML singleton;
- GTK CSS for FHUD-owned GTK surfaces while the migration exists;
- optional complete GTK-theme and Qt/QSS/Kvantum targets when their component
  coverage is explicitly maintained.

Each adapter declares unsupported tokens instead of approximating them silently.
Applications consume semantic roles such as `surface`, `focus`, `danger`, and
`spaceCompact`; target-specific names stay inside adapters. A future Stylix
radius option can become the default input without changing consumers.

## Current boundary

`src/appearance.nix` is the toolkit-neutral geometry source. `src/theme.nix` is
the same Base16 scheme given to Stylix. Hyprland and the shell consume generated
representations of those values; neither consumes the other's configuration.
The Quickshell migration should preserve this boundary by generating a QML
singleton instead of parsing `hyprctl` output or importing GTK values.
