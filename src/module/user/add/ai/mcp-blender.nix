# Provides complementary Blender control and asset workflows through the shared MCP gateway.
{
  config,
  lib,
  pkgs,
  ...
}: let
  controlServer = pkgs.callPackage ../../../../packages/blender-mcp.nix {};
  assetServer = pkgs.callPackage ../../../../packages/mcp-for-blender.nix {};
  blender = config.programs.blender;
  controlConnection = blender.extensions.mcp.settings;
  assetPort = 9876;
in {
  imports = [
    ../application/blender.nix
    ../application/mcp-gateway.nix
  ];

  programs.blender = {
    enable = true;
    # Upstream requires online access even for its local socket bridge.
    settings.system.use_online_access = true;
    extensions = {
      mcp = {
        source = controlServer.extension;
        settings = {
          host = "127.0.0.1";
          port = 9877;
          use_autostart = true;
        };
      };
      mcp_assets.source = assetServer.extension;
    };
  };

  assertions = [
    {
      assertion = lib.versionAtLeast blender.package.version "5.1";
      message = "The Blender MCP integrations require Blender 5.1 or newer.";
    }
    {
      assertion = controlConnection.port != assetPort;
      message = "Blender control and asset add-ons must use distinct bridge ports.";
    }
  ];

  # Poly Haven works without credentials. Other provider credentials must reach
  # Blender's own runtime environment rather than Nix-generated preferences.
  services.mcpGateway.servers = {
    blender = {
      command = lib.getExe controlServer;
      environment = {
        BLENDER_MCP_HOST = controlConnection.host;
        BLENDER_MCP_PORT = toString controlConnection.port;
        BLENDER_PATH = lib.getExe blender.package;
      };
    };
    blender-assets = {
      command = lib.getExe assetServer;
      environment = {
        BLENDER_HOST = "127.0.0.1";
        BLENDER_PORT = toString assetPort;
        DISABLE_TELEMETRY = "true";
      };
      tools = [
        "search_assets"
        "import_asset"
        "generate_3d"
        "look"
        "get_addon_status"
        "get_scene_info"
      ];
    };
  };
}
