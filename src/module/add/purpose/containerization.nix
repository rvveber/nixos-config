{
  pkgs,
  config,
  ...
}: {
  # Enable common container config files in /etc/containers
  virtualisation.containers.enable = true;
  virtualisation = {
    podman = {
      enable = true;

      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;

      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  # Useful other development tools
  environment.systemPackages = with pkgs; [
    #dive # look into docker image layers
    #podman-tui # status of containers in the terminal
    podman-compose
    # According to RedHat in the future we should switch to `podman play kube` instead of `docker compose up`
    # https://www.redhat.com/sysadmin/podman-compose-docker-compose
    # https://www.redhat.com/sysadmin/compose-kubernetes-podman
  ];
}
