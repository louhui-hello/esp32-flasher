# SPDX-License-Identifier: GPL-3.0-only
[CmdletBinding()]
param([string]$Python = 'C:\Espressif\tools\python\python.exe')
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$taskRoot = $PSScriptRoot
$taskVenv = Join-Path $taskRoot 'build\esptool-venv'
$taskVenvPython = Join-Path $taskVenv 'Scripts\python.exe'
$taskWork = Join-Path $taskRoot 'build\esptool-pyinstaller'
$taskDist = Join-Path $taskRoot 'dist\llvm-static'
if (-not (Test-Path -LiteralPath $taskVenvPython)) {
    & $Python -m venv $taskVenv
    if ($LASTEXITCODE -ne 0) { throw 'Failed to create esptool packaging venv' }
}
New-Item -ItemType Directory -Path $taskWork -Force | Out-Null
New-Item -ItemType Directory -Path $taskDist -Force | Out-Null
& $taskVenvPython -m pip --disable-pip-version-check install -r (Join-Path $taskRoot 'packaging\esptool-requirements.txt') 2>&1 | Tee-Object -FilePath (Join-Path $taskWork 'dependencies.log')
if ($LASTEXITCODE -ne 0) { throw 'Failed to install esptool packaging dependencies' }
& $taskVenvPython -m PyInstaller --noconfirm --onefile --console --noupx --name esptool --collect-all esptool --collect-all esp_pylib --distpath (Join-Path $taskWork 'dist') --workpath (Join-Path $taskWork 'work') --specpath $taskWork (Join-Path $taskRoot 'packaging\esptool_entry.py') 2>&1 | Tee-Object -FilePath (Join-Path $taskWork 'pyinstaller.log')
if ($LASTEXITCODE -ne 0) { throw 'esptool PyInstaller build failed' }
$taskFrozen = Join-Path $taskWork 'dist\esptool.exe'
& $taskFrozen version
if ($LASTEXITCODE -ne 0) { throw 'Standalone esptool version check failed' }
Copy-Item -LiteralPath $taskFrozen -Destination $taskDist -Force
$taskLicenses = Join-Path $taskDist 'licenses'
New-Item -ItemType Directory -Path $taskLicenses -Force | Out-Null
$taskEsptoolLicense = & $taskVenvPython -c 'from importlib.metadata import distribution; d=distribution("esptool"); print(d.locate_file("esptool-5.6.0.dist-info/licenses/LICENSE"))'
if ($LASTEXITCODE -ne 0) { throw 'Failed to locate esptool license' }
Copy-Item -LiteralPath $taskEsptoolLicense -Destination (Join-Path $taskLicenses 'esptool-LICENSE.txt') -Force
$taskTools = Join-Path $taskRoot 'tools'
New-Item -ItemType Directory -Path $taskTools -Force | Out-Null
Copy-Item -LiteralPath $taskFrozen -Destination (Join-Path $taskTools 'esptool.exe') -Force
& $taskVenvPython (Join-Path $taskRoot 'packaging\collect_python_licenses.py') $taskLicenses
if ($LASTEXITCODE -ne 0) { throw 'Failed to collect Python dependency licenses' }
Write-Output "Standalone esptool: $taskDist\esptool.exe"
