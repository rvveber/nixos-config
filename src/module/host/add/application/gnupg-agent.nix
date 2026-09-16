# Enables the GnuPG agent with SSH and browser socket support.
_: {
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    enableBrowserSocket = true;
  };
}
