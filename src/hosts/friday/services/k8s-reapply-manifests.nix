{pkgs, ...}: let
  manifestsRoot = toString ../k8s;
  reapplyScript = pkgs.writeShellScript "k8s-reapply-manifests" ''
    set -eu
    kubeconfig="/etc/rancher/k3s/k3s.yaml"

    if [ ! -f "$kubeconfig" ]; then
      echo "Kubeconfig not found at $kubeconfig. Skipping manifest re-apply."
      exit 0
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
      echo "Kubernetes API not ready. Skipping manifest re-apply."
      exit 0
    fi

    ${pkgs.kubectl}/bin/kubectl --kubeconfig "$kubeconfig" apply -f "${manifestsRoot}/base"
    for dir in "${manifestsRoot}/apps"/*; do
      if [ -d "$dir" ]; then
        ${pkgs.kubectl}/bin/kubectl --kubeconfig "$kubeconfig" apply -f "$dir"
      fi
    done
  '';
in {
  systemd.services."k8s-reapply-manifests" = {
    description = "Re-apply Kubernetes manifests";
    wants = [
      "k3s.service"
      "nix-secrets-2-kubernetes-secrets.service"
    ];
    after = [
      "k3s.service"
      "nix-secrets-2-kubernetes-secrets.service"
    ];
    serviceConfig.Type = "oneshot";
    script = ''${reapplyScript}'';
  };

  system.activationScripts.k8sReapplyManifests = {
    deps = ["k8sSecretsSync"];
    text = ''
      ${reapplyScript} || true
    '';
  };
}
