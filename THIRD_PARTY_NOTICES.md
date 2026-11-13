# Third-party components

The application source in this repository is GPL-3.0-only. Third-party code retains its own license.

## Qt

The LLVM build uses the open-source static Qt 6.12.0 package from:
https://github.com/yuanpeirong/buildQt/releases/tag/Qt6.12.0_rev0

Asset: `Qt_6.12.0-static-Release_llvm-mingw22.1.7_64_UCRT.7z`.
SHA-256: `5c370272bbeacad9758347c50d735acefc0bde8cbdb1636ad558e0960b87e045`.
Qt modules used include Qt Core, Gui, Network, Qml, Quick, QuickControls2, SerialPort, Svg and selected image/QML plugins.
Qt includes code under GPL, LGPL and permissive third-party licenses. These licenses are not replaced by the application license.
Copies of the Qt license texts and attribution metadata are provided in `packaging/licenses/qt/`.
The unmodified upstream Qt build script is kept at `packaging/qt-upstream-build.cmd` for provenance.
Qt upstream source: https://download.qt.io/official_releases/qt/6.12/6.12.0/single/qt-everywhere-src-6.12.0.tar.xz .
Qt module repositories: https://code.qt.io/qt/ .
Qt licensing information: https://www.qt.io/licensing/open-source-lgpl-obligations .

## esptool

Version: 5.6.0. License: GPL-2.0-or-later.
Source: https://github.com/espressif/esptool/tree/v5.6.0 .
The application launches esptool as a separate command-line process.
`packaging/esptool_entry.py` uses the upstream CLI entry point.
The fixed Python dependency versions are recorded in `packaging/esptool-requirements.txt`.

## Python and PyInstaller

Python 3.11 and its runtime are bundled in the standalone backend under the Python Software Foundation license.
Source: https://www.python.org/downloads/source/ .
PyInstaller 6.22.3 uses GPL-2.0-or-later with its bootloader exception.
Source and exception: https://github.com/pyinstaller/pyinstaller/tree/v6.22.3 .
PyInstaller is a build dependency; the release includes its bootloader and runtime hooks.
Python dependencies retain their respective licenses. Installed dependency license files are collected into `licenses/python-dependencies/` in the portable package.

## Build tools

LLVM-MinGW/Clang 22.1.7, CMake and Ninja are build tools. Their separate packages are not uploaded as application source.
LLVM-MinGW: https://github.com/mstorsjo/llvm-mingw .
For rebuilding, install an ABI-compatible toolchain and use `build-llvm-static.ps1`; tool locations can be overridden using script parameters.
