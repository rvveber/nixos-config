# Runs CLIProxyAPI as a loopback OpenAI-compatible endpoint that serves
# subscription-backed providers (Codex, Claude, Gemini, ...) behind one API key.
#
# Provider logins are interactive and stored in the state directory, e.g.:
#   cliproxyapi -config ~/.local/state/cliproxyapi/config.yaml -codex-login
# The API key for clients is in `authTokenFile`.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.cliproxyapi;
  json = pkgs.formats.json {};
  stateRoot = "${config.xdg.stateHome}/cliproxyapi";
  authTokenFile = "${stateRoot}/api-key";
  runtimeConfigFile = "${stateRoot}/config.yaml";

  # The API key is injected at start so that it never enters the Nix store.
  baseConfiguration = json.generate "cliproxyapi-base.json" {
    config-version = 8;
    server = {
      host = "127.0.0.1";
      inherit (cfg) port;
    };
    oauth.auth-dir = "${stateRoot}/auth";
  };

  prepareRuntime = pkgs.writeShellApplication {
    name = "prepare-cliproxyapi";
    runtimeInputs = [pkgs.coreutils pkgs.jq pkgs.openssl];
    text = ''
      umask 077
      install -d -m 0700 ${lib.escapeShellArg stateRoot} ${lib.escapeShellArg "${stateRoot}/auth"}

      if [ ! -s ${lib.escapeShellArg authTokenFile} ]; then
        openssl rand -hex 32 > ${lib.escapeShellArg authTokenFile}
      fi

      # JSON is valid YAML, so jq can render the final configuration.
      jq --arg key "$(cat ${lib.escapeShellArg authTokenFile})" \
        '. + {access: {"api-keys": [$key]}}' \
        ${baseConfiguration} > ${lib.escapeShellArg runtimeConfigFile}
    '';
  };
in {
  options.services.cliproxyapi = {
    package = lib.mkPackageOption pkgs "cliproxyapi" {};

    port = lib.mkOption {
      type = lib.types.port;
      default = 8317;
      description = "Loopback port of the OpenAI-compatible endpoint.";
    };
  };

  config = {
    home.packages = [cfg.package];

    systemd.user.services.cliproxyapi = {
      Unit.Description = "CLIProxyAPI";
      Service = {
        ExecStartPre = lib.getExe prepareRuntime;
        ExecStart = "${lib.getExe cfg.package} -config ${runtimeConfigFile}";
        Restart = "on-failure";
        RestartSec = "5s";
        UMask = "0077";
      };
      Install.WantedBy = ["default.target"];
    };
  };
}
