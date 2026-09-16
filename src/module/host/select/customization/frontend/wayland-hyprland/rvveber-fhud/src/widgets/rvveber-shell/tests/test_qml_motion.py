import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


class MotionTests(unittest.TestCase):
    def test_motion_lifecycle_and_reduced_motion(self):
        fixture = Path(__file__).with_name("motion.qml")
        for reduced in ("0", "1"):
            with self.subTest(reduced_motion=reduced), tempfile.TemporaryDirectory() as runtime:
                configuration = Path(runtime) / "config"
                shutil.copytree(fixture.parent.parent / "qml", configuration / "qml")
                shutil.copy(fixture, configuration / "shell.qml")
                environment = os.environ.copy()
                environment.pop("WAYLAND_DISPLAY", None)
                environment.update(
                    QT_QPA_PLATFORM="offscreen",
                    QT_QUICK_BACKEND="software",
                    XDG_RUNTIME_DIR=runtime,
                    XDG_CACHE_HOME=runtime,
                    RVVEBER_FHUD_REDUCED_MOTION=reduced,
                )
                result = subprocess.run(
                    ["qs", "--path", str(configuration)],
                    env=environment,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    text=True,
                    timeout=15,
                    check=False,
                )
                self.assertEqual(result.returncode, 0, result.stdout)
                self.assertNotIn("WARN scene:", result.stdout)
                self.assertNotIn("ERROR:", result.stdout)
                self.assertIn("MOTION CHECKS PASSED", result.stdout)
