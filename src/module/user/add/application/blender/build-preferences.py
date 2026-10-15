"""Generate Blender's complete preferences from the Nix module specification."""

import json
import sys
from pathlib import Path

import addon_utils
import bpy
import tomllib


def apply_settings(target, settings):
    for name, value in settings.items():
        if isinstance(value, dict):
            apply_settings(getattr(target, name), value)
        else:
            setattr(target, name, value)


specification = Path(sys.argv[sys.argv.index("--") + 1])
with specification.open() as stream:
    specification = json.load(stream)

preferences = bpy.context.preferences
apply_settings(preferences, specification["settings"])

if specification["extensions"]:
    repository = specification["repository"]
    preferences.extensions.repos.new(
        name="Nix",
        module="nixos",
        custom_directory=repository,
        source="SYSTEM",
    )
    for name, extension in specification["extensions"].items():
        with (Path(repository) / name / "blender_manifest.toml").open("rb") as stream:
            manifest = tomllib.load(stream)
        if manifest["id"] != name or manifest["type"] != "add-on":
            raise ValueError(f"Extension {name!r} must be an add-on with matching id")

        module = f"bl_ext.nixos.{name}"
        if addon_utils.enable(module, default_set=True) is None:
            raise RuntimeError(f"Could not enable Blender extension {name!r}")
        apply_settings(preferences.addons[module].preferences, extension["settings"])

if bpy.ops.wm.save_userpref() != {"FINISHED"}:
    raise RuntimeError("Could not save Blender preferences")
