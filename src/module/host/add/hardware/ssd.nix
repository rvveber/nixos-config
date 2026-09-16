# Enables weekly filesystem trimming for solid-state storage.
_: {
  # periodic TRIM
  services.fstrim = {
    enable = true;
    interval = "weekly"; # the default
  };
}
