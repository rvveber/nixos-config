_: {
  # periodic TRIM
  services.fstrim = {
    enable = true;
    interval = "weekly"; # the default
  };
}
