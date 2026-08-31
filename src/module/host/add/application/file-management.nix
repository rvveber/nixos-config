# Desktop-independent foundations for file management customizations.
{pkgs, ...}: {
  # UDisks provides the privileged device operations used by user-level
  # automounters, avoiding root commands for removable media.
  services.udisks2.enable = true;

  xdg.portal = {
    enable = true;
    # Route xdg-open through the portal so applications launched from FHS
    # environments still reach the host's MIME handlers.
    xdgOpenUsePortal = true;
    # GTK implements generic portal interfaces omitted by wlroots compositors.
    extraPortals = [pkgs.xdg-desktop-portal-gtk];
  };
}
