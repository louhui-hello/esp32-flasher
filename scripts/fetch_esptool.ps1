# SPDX-License-Identifier: GPL-3.0-only
# Compatibility entry point: build a standalone backend in an isolated venv.
[CmdletBinding()]
param(
    [string]$Version = '5.6.0',
    [string]$Dest = (Join-Path $PSScriptRoot '..\tools'),
    [string]$Python = 'C:\Espressif\tools\python\python.exe'
)
$ErrorActionPreference = 'Stop'
if ($Version -ne '5.6.0') {
    throw 'Update packaging/esptool-requirements.txt before selecting another esptool version.'
}
$taskRoot = Split-Path $PSScriptRoot
& (Join-Path $taskRoot 'package-esptool.ps1') -Python $Python
New-Item -ItemType Directory -Path $Dest -Force | Out-Null
$taskSource = [IO.Path]::GetFullPath((Join-Path $taskRoot 'tools\esptool.exe'))
$taskDestination = [IO.Path]::GetFullPath((Join-Path $Dest 'esptool.exe'))
if ($taskSource -ne $taskDestination) {
    Copy-Item -LiteralPath $taskSource -Destination $taskDestination -Force
}
Write-Output "Standalone backend: $taskDestination"
