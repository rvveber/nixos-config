{
  pkgs,
  source,
  theme,
}: let
  parameters = {
    OUTPUT_WIDTH = 4096;
    OUTPUT_HEIGHT = 2560;
    WORK_BASE_RESOLUTION = 2500;
    CONTOUR_LEVEL_COUNT = 10;
    OUTER_LINE_DARK_FRACTION = 38;
    BASE_STROKE_WIDTH_PX = 1.5;
    TOP_THICK_LEVEL_COUNT = 2;
    TOP_THICK_STROKE_FACTOR = 2.0;
    OUTER_DARK_LINE_OPACITY = 0.3;
    INNER_LIGHT_LINE_OPACITY = 0.8;
    DASH_EVERY_NTH_LEVEL = 0;
    DASH_PATTERN_PX = "30,50";
    DASH_OFFSET_PX = 0;
    SYMBOL_EVERY_NTH_LEVEL = 0;
    SYMBOL_SHAPE = "pipe";
    SYMBOL_SIZE_PX = 20;
    SYMBOL_STROKE_PX = 0.3;
    SYMBOL_SPACING_PX = 32;
    SYMBOL_OPACITY = 0.5;
    SYMBOL_KEEP_BASE_LINE = false;
    SYMBOL_ROTATE_WITH_PATH = true;
    VIGNETTE_INSET_X_PX = 0;
    VIGNETTE_INSET_Y_PX = 150;
    VIGNETTE_COLOR = theme.base00;
    VIGNETTE_OPACITY = 1.0;
    VIGNETTE_EXPONENT = 1.8;
    LARGE_BLOB_GRID_X = 1;
    LARGE_BLOB_GRID_Y = 3;
    SMALL_BLOB_GRID_X = 3;
    SMALL_BLOB_GRID_Y = 6;
    LARGE_BLOB_STRENGTH = 1.0;
    SMALL_BLOB_STRENGTH = 0.6;
    BLOB_POSITION_JITTER = 0.7;
    BLOB_MARGIN_FRACTION = 0.22;
    AA_SUPERSAMPLE = 1;
    BACKGROUND = theme.base00;
    FOREGROUND = theme.base05;
  };
in
  pkgs.runCommand "wallpaper.png" (parameters
    // {
      buildInputs = [
        (pkgs.python3.withPackages (python: [python.numpy python.contourpy]))
        pkgs.librsvg
        pkgs.vips
      ];
    }) ''
    export PY=python3
    export RSVG=rsvg-convert
    export VIPS=vips
    bash ${source}/src/scripts/generate-topography-wallpaper.sh
  ''
