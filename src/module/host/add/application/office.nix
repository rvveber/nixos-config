{
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages =
    (with pkgs; [
      # Primary open-source office suite for ODT editing.
      libreoffice

      # Modern and practical open-source PDF tooling.
      kdePackages.okular
      pdfarranger
      xournalpp
    ])
    ++ lib.optionals (pkgs ? onlyoffice-desktopeditors) [
      # Modern UI office suite with strong document compatibility.
      pkgs.onlyoffice-desktopeditors
    ];
}
