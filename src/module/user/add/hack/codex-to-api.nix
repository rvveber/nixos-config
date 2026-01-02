{
  pkgs,
  lib,
  config,
  ...
}: let
  chatMockSrc = pkgs.fetchFromGitHub {
    owner = "RayBytes";
    repo = "ChatMock";
    rev = "v1.35";
    sha256 = "0m6rj7kn3ymf61340ldd1wyg4alg7axah4yb4b9xifyv00d57758";
  };

  pythonEnv = pkgs.python313.withPackages (ps: [
    ps.certifi
    ps.click
    ps.flask
    ps.idna
    ps.itsdangerous
    ps.jinja2
    ps.markupsafe
    ps.requests
    ps.urllib3
    ps.werkzeug
  ]);

  codexToApiPkg = pkgs.writeShellApplication {
    name = "codex-to-api";
    runtimeInputs = [
      pkgs.codex
    ];
    text = ''
      exec ${pythonEnv}/bin/python ${chatMockSrc}/chatmock.py "$@"
    '';
  };

  cfg = config.services.codexToApi;
  dataDir = "${config.home.homeDirectory}/.chatgpt-local";
in {
  options.services.codexToApi = {
    enable = lib.mkEnableOption "Codex-to-API (ChatMock)";
    package = lib.mkOption {
      type = lib.types.package;
      default = codexToApiPkg;
    };
    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 8000;
    };
    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
    };
  };

  config = lib.mkMerge [
    {services.codexToApi.enable = lib.mkDefault true;}
    (lib.mkIf cfg.enable {
      home.packages = [
        cfg.package
      ];

      systemd.user.services."codex-to-api" = {
        Unit = {
          Description = "Codex-to-API (ChatMock)";
          ConditionPathExists = "${dataDir}/auth.json";
        };

        Service = {
          Environment = [
            "CHATGPT_LOCAL_HOME=${dataDir}"
          ];
          ExecStart =
            "${cfg.package}/bin/codex-to-api serve --host ${cfg.host} --port ${toString cfg.port}"
            + lib.optionalString (cfg.extraArgs != []) " ${lib.escapeShellArgs cfg.extraArgs}";
          Restart = "on-failure";
          RestartSec = "2s";
        };

        Install = {
          WantedBy = [
            "default.target"
          ];
        };
      };
    })
  ];
}
