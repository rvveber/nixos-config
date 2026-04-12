{pkgs, ...}: let
  namespace = "friday";
  secretName = "nix-secrets";
  secretGlob = "/run/secrets/host_friday_k8s_*";
  syncScript = pkgs.writeShellScript "nix-secrets-2-kubernetes-secrets" ''
    set -eu
    kubeconfig="/etc/rancher/k3s/k3s.yaml"

    if [ ! -f "$kubeconfig" ]; then
      echo "Kubeconfig not found at $kubeconfig. Skipping secret sync."
      exit 0
    fi

    args=""
    for file in ${secretGlob}; do
      if [ -f "$file" ]; then
        name="$(basename "$file")"
        args="$args --from-file=$name=$file"
      fi
    done

    if [ -z "$args" ]; then
      echo "No files found in ${secretGlob} to sync to Kubernetes." >&2
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
      echo "Kubernetes API not ready. Skipping secret sync."
      exit 0
    fi

    ${pkgs.kubectl}/bin/kubectl --kubeconfig "$kubeconfig" create namespace ${namespace} \
      --dry-run=client -o yaml | ${pkgs.kubectl}/bin/kubectl --kubeconfig "$kubeconfig" apply -f -

    # shellcheck disable=SC2086
    ${pkgs.kubectl}/bin/kubectl --kubeconfig "$kubeconfig" -n ${namespace} create secret generic ${secretName} \
      $args \
      --dry-run=client -o yaml | ${pkgs.kubectl}/bin/kubectl --kubeconfig "$kubeconfig" apply -f -
  '';
in {
  systemd.services."nix-secrets-2-kubernetes-secrets" = {
    description = "Create/update shared Kubernetes secret";
    wants = [
      "k3s.service"
      "sops-install-secrets.service"
    ];
    after = [
      "k3s.service"
      "sops-install-secrets.service"
    ];
    serviceConfig.Type = "oneshot";
    script = ''${syncScript}'';
  };

  system.activationScripts.k8sSecretsSync = {
    text = ''
      ${syncScript} || true
    '';
  };
}
