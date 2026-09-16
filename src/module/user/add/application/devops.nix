# Installs per-user Kubernetes administration and documentation tools.
{pkgs, ...}: {
  home.packages = with pkgs; [
    k3sup
    kubernetes-helm
    kubectl
    kubelogin-oidc
    helm-docs
  ];
}
