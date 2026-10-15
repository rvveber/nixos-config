# Installs Blender with fully Nix-generated preferences and local extensions.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.blender;
  json = pkgs.formats.json {};
  extensionRepository = pkgs.linkFarm "blender-extensions" (lib.mapAttrsToList (name: extension: {
      inherit name;
      path = extension.source;
    })
    cfg.extensions);
  specification = json.generate "blender-preferences.json" {
    inherit (cfg) settings;
    repository = toString extensionRepository;
    extensions =
      lib.mapAttrs (_: extension: {
        inherit (extension) settings;
      })
      cfg.extensions;
  };
  preferences = pkgs.runCommand "blender-preferences-${cfg.package.version}" {} ''
    export HOME="$TMPDIR/home"
    export XDG_CONFIG_HOME="$HOME/.config"
    export BLENDER_USER_CONFIG="$out"
    export BLENDER_USER_EXTENSIONS="$TMPDIR/extensions"
    mkdir -p "$HOME" "$out"

    ${lib.getExe cfg.package} --background --factory-startup \
      --python-exit-code 1 --python ${./blender/build-preferences.py} \
      -- ${specification}
    test -s "$out/userpref.blend"
  '';
in {
  options.programs.blender = {
    enable = lib.mkEnableOption "Blender with declarative preferences";
    package = lib.mkPackageOption pkgs "blender" {};

    settings = lib.mkOption {
      type = lib.types.attrsOf json.type;
      default = {};
      example = {view.show_splash = false;};
      description = ''
        Nested properties of bpy.context.preferences, applied to factory defaults
        at build time. Nix owns the entire userpref.blend; declare persistent
        changes here rather than saving preferences in Blender's UI.
      '';
    };

    extensions = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          source = lib.mkOption {
            type = lib.types.path;
            description = "Unpacked extension directory containing blender_manifest.toml; the attribute name must match its id.";
          };
          settings = lib.mkOption {
            type = lib.types.attrsOf json.type;
            default = {};
            description = "Nested properties of this extension's AddonPreferences.";
          };
        };
      });
      default = {};
      description = "Extensions enabled from a read-only Nix Store repository.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [cfg.package];
    programs.blender.settings.use_preferences_save = lib.mkDefault false;

    # Blender versions have separate configuration directories. Building with
    # the selected package keeps the binary preferences and directory in sync.
    xdg.configFile."blender/${lib.versions.majorMinor cfg.package.version}/config/userpref.blend".source = "${preferences}/userpref.blend";
  };
}
