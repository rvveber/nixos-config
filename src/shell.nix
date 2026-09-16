# Provides the repository's formatting, analysis and regression-test tools.
{pkgs}:
pkgs.mkShellNoCC {
  packages = with pkgs; [
    alejandra
    deadnix
    nixd
    python3
    ruff
    shellcheck
    statix
    stylua
  ];
}
