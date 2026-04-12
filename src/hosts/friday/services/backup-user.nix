_: {
  # Trusted backup account.
  # Backup access happens via SSH + sudo
  users.users.backup-service = {
    isSystemUser = true;
    group = "backup-service";
    description = "Backup user";
    createHome = false;
    home = "/var/empty";
    useDefaultShell = true;
    extraGroups = ["wheel"];

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILu0fDhL8iUAZvCOHsA36wT04mHYvcD3cCJfK13lhKE5"
    ];
  };

  users.groups.backup-service = {};

  security.sudo.extraRules = [
    {
      users = ["backup-service"];
      commands = [
        {
          command = "ALL";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];
}
