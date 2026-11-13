# SPDX-License-Identifier: GPL-3.0-only
[CmdletBinding()]
param(
    [ValidateRange(1,64)][int]$Jobs = 12,
    [string]$QtPrefix = 'G:\lang\Qt-static-6.12.0-llvm\llvm-mingw22.1.7_64_UCRT',
    [string]$CompilerBin = 'G:\lang\Qt\Tools\llvm-mingw2217_64\bin',
    [string]$CMake = 'G:\lang\Qt\Tools\CMake_64\bin\cmake.exe',
    [string]$Ninja = 'G:\lang\ninja\ninja.exe',
    [string]$Python = 'C:\Espressif\tools\python\python.exe',
    [switch]$BundleEsptool
)
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$taskRoot = $PSScriptRoot
$taskBuild = Join-Path $taskRoot 'build\llvm-static'
$taskDist = Join-Path $taskRoot 'dist\llvm-static'
$taskQt = $QtPrefix
$taskCompiler = $CompilerBin
$taskCmake = $CMake
$taskNinja = $Ninja
foreach ($taskRequired in @("$taskQt\bin\qmake.exe", "$taskCompiler\clang++.exe", $taskCmake, $taskNinja)) {
    if (-not (Test-Path -LiteralPath $taskRequired)) { throw "Missing build component: $taskRequired" }
}
$env:PATH = "$taskCompiler;$(Split-Path $taskCmake);$(Split-Path $taskNinja);$env:PATH"
foreach ($taskVariable in @('CC','CXX','CFLAGS','CXXFLAGS','LDFLAGS','CMAKE_PREFIX_PATH','CMAKE_TOOLCHAIN_FILE','QTDIR','QMAKESPEC','QT_PLUGIN_PATH','QML_IMPORT_PATH','QML2_IMPORT_PATH')) {
    Remove-Item -LiteralPath "Env:$taskVariable" -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Path $taskBuild -Force | Out-Null
& (Join-Path $taskRoot 'package-esptool.ps1') -Python $Python
if ($LASTEXITCODE -ne 0) { throw 'Standalone esptool packaging failed' }
$taskBundle = if ($BundleEsptool) { 'ON' } else { 'OFF' }
$taskLog = Join-Path $taskBuild 'build-llvm.log'
& $taskCmake -S $taskRoot -B $taskBuild -G Ninja "-DCMAKE_PREFIX_PATH=$taskQt" "-DCMAKE_CXX_COMPILER=$taskCompiler/clang++.exe" "-DCMAKE_MAKE_PROGRAM=$taskNinja" '-DCMAKE_BUILD_TYPE=Release' '-DESPFLASHER_STATIC_QT=ON' "-DESPFLASHER_BUNDLE_ESPTOOL=$taskBundle" 2>&1 | Tee-Object -FilePath $taskLog
if ($LASTEXITCODE -ne 0) { throw 'CMake configuration failed' }
& $taskCmake --build $taskBuild --parallel $Jobs 2>&1 | Tee-Object -FilePath $taskLog -Append
if ($LASTEXITCODE -ne 0) { throw 'LLVM static build failed' }
New-Item -ItemType Directory -Path $taskDist -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $taskBuild 'esp32flasher.exe') -Destination $taskDist -Force
@'
ESP32 Flasher - LLVM static Release

运行 esp32flasher.exe；请保留同目录的 esptool.exe。
Qt 6.12 已静态链接，不需要额外 Qt DLL。
esptool 5.6.0 由 PyInstaller 打包，内含 Python，不需要安装 Python 或激活 venv。
编译器：LLVM-MinGW / Clang 22.1.7，x86_64，UCRT，Release。

重新构建：在项目根目录运行 build-llvm-static.ps1。
构建依赖仅安装到 build/esptool-venv；venv 不需要随发布包分发。
程序启动与 esptool 离线命令已验证，未对设备执行擦除或烧录。

第三方后端 esptool 使用 GPL-2.0-or-later；源代码与许可证见 https://github.com/espressif/esptool 。
'@ | Set-Content -LiteralPath (Join-Path $taskDist '使用说明.txt') -Encoding utf8
Copy-Item -LiteralPath (Join-Path $taskRoot 'LICENSE') -Destination $taskDist -Force
Copy-Item -LiteralPath (Join-Path $taskRoot 'THIRD_PARTY_NOTICES.md') -Destination $taskDist -Force
$taskBundledNotices = Join-Path $taskRoot 'packaging\licenses'
if (Test-Path -LiteralPath $taskBundledNotices) {
    Copy-Item -LiteralPath $taskBundledNotices -Destination $taskDist -Recurse -Force
}
Write-Output "LLVM static release: $taskDist"
