# Provides the repository's formatting, analysis and scripting tools.
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

  # Lets repository scripts detect this toolchain; IN_NIX_SHELL is also set by
  # unrelated nix-shells that lack it.
  env.NIXOS_CONFIG_DEV_SHELL = "1";
}
