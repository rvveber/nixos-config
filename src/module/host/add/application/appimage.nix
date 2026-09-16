# Enables AppImage execution through NixOS binary-format integration.
_: {
  programs.appimage = {
    enable = true;
    binfmt = true;
  };
}
