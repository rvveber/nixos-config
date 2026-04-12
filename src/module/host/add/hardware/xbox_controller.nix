_: {
  # Enable xpadneo for better controller support
  hardware.xpadneo.enable = true;
  hardware.bluetooth.settings = {
    General = {
      # Allows handshake with newer firmwares using privacy features
      Privacy = "device";
      JustWorksRepairing = "always";
      Class = "0x000100";
      FastConnectable = true;
      # Fast reqconnection attempts
      ReconnectAttempts = 7;
      ReconnectIntervals = "1, 2, 4, 8, 16, 32, 64";
    };
  };
}
