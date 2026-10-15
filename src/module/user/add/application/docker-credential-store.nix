# Configures Docker registry logins to use pass instead of plaintext auth in
# ~/.docker/config.json.
{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}: let
  dockerConfig = "${config.home.homeDirectory}/.docker/config.json";
  configureDockerCredentialStore = pkgs.writeShellScript "configure-docker-credential-store" ''
    set -eu

    config_file=${lib.escapeShellArg dockerConfig}
    config_dir="$(${pkgs.coreutils}/bin/dirname "$config_file")"
    ${pkgs.coreutils}/bin/mkdir -p "$config_dir"

    if [ -f "$config_file" ]; then
      temporary_file="$(${pkgs.coreutils}/bin/mktemp "$config_dir/config.json.XXXXXX")"
      trap '${pkgs.coreutils}/bin/rm -f "$temporary_file"' EXIT
      ${pkgs.jq}/bin/jq '. + {credsStore: "pass"}' "$config_file" > "$temporary_file"
    else
      temporary_file="$config_dir/config.json.new"
      trap '${pkgs.coreutils}/bin/rm -f "$temporary_file"' EXIT
      ${pkgs.coreutils}/bin/printf '%s\n' '{"credsStore":"pass"}' > "$temporary_file"
    fi

    ${pkgs.coreutils}/bin/chmod 0600 "$temporary_file"
    ${pkgs.coreutils}/bin/mv "$temporary_file" "$config_file"
    trap - EXIT
  '';
in {
  home.activation.configureDockerCredentialStore = lib.mkIf osConfig.virtualisation.docker.enable (
    lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [ -z "''${DRY_RUN_CMD:-}" ]; then
        ${configureDockerCredentialStore}
      else
        echo "Would configure Docker to use the pass credential store"
      fi
    ''
  );
}
