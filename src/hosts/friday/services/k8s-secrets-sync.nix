{
  config,
  lib,
  pkgs,
  ...
}: let
  namespace = "friday";
  secretName = "nix-secrets";
  syncUnit = "nix-secrets-2-kubernetes-secrets.service";
  secretNames = map (name: "host_friday_k8s_${name}") [
    "lldap_admin_password"
    "lldap_jwt_secret"
    "lldap_database_url"
    "postgres_admin_password"
    "postgres_forgejo_password"
    "postgres_lldap_password"
    "postgres_stalwart_password"
    "forgejo_admin_password"
    "forgejo_internal_token"
    "forgejo_oauth2_jwt_secret"
    "forgejo_secret_key"
    "stalwart_dkim_private_key"
    "cloudflare_api_token"
  ];
  secretFileArgs =
    lib.escapeShellArgs (map (name: "--from-file=${name}=${config.sops.secrets.${name}.path}")
      secretNames);
in {
  sops.secrets = lib.genAttrs secretNames (_: {
    restartUnits = [syncUnit];
  });

  systemd.services."nix-secrets-2-kubernetes-secrets" = {
    description = "Create/update shared Kubernetes secret";
    wantedBy = ["multi-user.target"];
    wants = ["k3s.service"];
    after = ["k3s.service"];
    serviceConfig = {
      Type = "oneshot";
      Restart = "on-failure";
      RestartSec = "10s";
    };
    script = ''
      kubeconfig="/etc/rancher/k3s/k3s.yaml"

      if [ ! -f "$kubeconfig" ]; then
        echo "Kubeconfig not found at $kubeconfig." >&2
        exit 1
      fi

      api_ready=0
      for _ in $(seq 1 90); do
        if ${pkgs.kubectl}/bin/kubectl --kubeconfig "$kubeconfig" get --raw=/readyz >/dev/null 2>&1; then
          api_ready=1
          break
        fi
        sleep 2
      done

      if [ "$api_ready" -ne 1 ]; then
        echo "Kubernetes API not ready." >&2
        exit 1
      fi

      ${pkgs.kubectl}/bin/kubectl --kubeconfig "$kubeconfig" create namespace ${namespace} \
        --dry-run=client -o yaml | ${pkgs.kubectl}/bin/kubectl --kubeconfig "$kubeconfig" apply -f -

      ${pkgs.kubectl}/bin/kubectl --kubeconfig "$kubeconfig" -n ${namespace} create secret generic ${secretName} \
        ${secretFileArgs} \
        --dry-run=client -o yaml | ${pkgs.kubectl}/bin/kubectl --kubeconfig "$kubeconfig" apply -f -
    '';
  };
}
