# Selects rootless Podman with Docker CLI compatibility and pass-backed
# credentials. Docker clients reach the user's Podman API socket through
# DOCKER_HOST, so container access does not grant root on the host.
{pkgs, ...}: {
  imports = [
    ../../../../add/application/containerization.nix
    ../../../../add/application/credential-store.nix
  ];

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
    docker-credential-helpers
    #dive # look into docker image layers
    #podman-tui # status of containers in the terminal
    podman-compose
    # According to RedHat in the future we should switch to `podman play kube` instead of `docker compose up`
    # https://www.redhat.com/sysadmin/podman-compose-docker-compose
    # https://www.redhat.com/sysadmin/compose-kubernetes-podman
  ];

  environment.sessionVariables = {
    PODMAN_COMPOSE_WARNING_LOGS = "false";
  };

  # The user socket is enabled by the Podman module; XDG_RUNTIME_DIR is only
  # known at login, so the variable is set at shell initialization.
  environment.extraInit = ''
    if [ -z "$DOCKER_HOST" -a -n "$XDG_RUNTIME_DIR" ]; then
      export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"
    fi
  '';

  virtualisation.containers.containersConf.settings.engine.credential_helpers = ["pass"];
}
