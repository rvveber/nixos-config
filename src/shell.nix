{pkgs}:
pkgs.mkShellNoCC {
  packages = with pkgs; [
    alejandra
    deadnix
    nixd
    statix
    stylua
  ];
}
