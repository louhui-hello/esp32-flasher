# SPDX-License-Identifier: GPL-3.0-only
"""Copy installed dependency license files into the portable distribution."""
from importlib.metadata import distributions
from pathlib import Path
import shutil
import sys

out = Path(sys.argv[1]) / "python-dependencies"
out.mkdir(parents=True, exist_ok=True)
manifest = []
for dist in sorted(distributions(), key=lambda d: d.metadata.get("Name", "").lower()):
    name = dist.metadata.get("Name", "unknown")
    version = dist.version
    copied = []
    for entry in dist.files or ():
        entry_path = Path(str(entry))
        if not any(part.lower().startswith(("license", "licence", "copying", "notice"))
                   for part in entry_path.parts):
            continue
        source = Path(dist.locate_file(entry))
        if not source.is_file():
            continue
        destination = out / f"{name}-{version}" / entry_path
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, destination)
        copied.append(str(destination.relative_to(out)))
    manifest.append(f"{name}=={version}\n" + "\n".join(copied))
python_license = Path(sys.base_prefix) / "LICENSE.txt"
if python_license.is_file():
    shutil.copyfile(python_license, out / "Python-LICENSE.txt")
(out / "DEPENDENCIES.txt").write_text("\n\n".join(manifest) + "\n", encoding="utf-8")
