_: {
  # AppImage is a tool to package desktop applications
  # This module enables AppImage support in NixOS
  programs.appimage = {
    enable = true;
    binfmt = true;
  };
}
