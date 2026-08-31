{
  slug = "FHUD";
  author = "github.com/rvveber";
  scheme = "FHUD";
  # Background scale: main surface, raised surface, then selections.
  base00 = "#000e14"; # Main background.
  base01 = "#001f27"; # Active line and subtle panels.
  base02 = "#003f49"; # Selected text and focused surfaces.

  # Foreground scale: comments must remain readable on base01 and base02.
  base03 = "#005662"; # Comments, invisibles, and bright black.
  base04 = "#1d6e79"; # Dimmed interface text.
  base05 = "#9dd7e1"; # Default text.
  base06 = "#ace5ee"; # Emphasized text.
  base07 = "#caffff"; # Highest-contrast text.

  # Syntax and semantic colors.
  base08 = "#e19db4"; # Errors, deletions, and variables.
  base09 = "#dce19d"; # Constants and urgent states.
  base0A = "#e1c19d"; # Warnings, types, and classes.
  base0B = "#9de1a0"; # Success, strings, and additions.
  base0C = "#2dc8dc"; # Support syntax and debug information.
  base0D = "#2dc8dc"; # Functions, links, and informational states. Often used.
  base0E = "#d69de1"; # Keywords, prompts, and headings.
  base0F = "#004662"; # Deprecated or language-specific syntax.

  # Base24 terminal brights used by applications which support 24 colors.
  base10 = "#e44471"; # Bright error.
  base11 = "#e2cf64"; # Bright urgent state.
  base12 = "#ffc400"; # Bright warning.
  base13 = "#00ff00"; # Bright success.
  base14 = "#bbff00"; # Bright debug.
  base15 = "#00a2ff"; # Bright information.
  base16 = "#ff51a8"; # Bright prompt.
  base17 = "#2dc8dc"; # Bright miscellaneous accent.
}
