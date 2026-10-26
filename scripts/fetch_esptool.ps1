# 从官方 release 下载 esptool，并只取出 esptool.exe 放到 tools/
param(
    [string]$Version = '5.6.0',
    [string]$Dest = (Join-Path $PSScriptRoot '..\tools')
)

$ErrorActionPreference = 'Stop'
$zipName = "esptool-v$Version-windows-amd64.zip"
$url = "https://github.com/espressif/esptool/releases/download/v$Version/$zipName"
$tmp = Join-Path $env:TEMP $zipName

New-Item -ItemType Directory -Force -Path $Dest | Out-Null
$target = Join-Path $Dest 'esptool.exe'

if (Test-Path $target) {
    Write-Output "已存在: $target"
    exit 0
}

Write-Output "下载 $url"
Invoke-WebRequest -Uri $url -OutFile $tmp -TimeoutSec 600

Write-Output "解压 $tmp"
$extract = Join-Path $env:TEMP "esptool-$Version"
Remove-Item $extract -Recurse -Force -ErrorAction SilentlyContinue
Expand-Archive -Path $tmp -DestinationPath $extract -Force

$found = Get-ChildItem $extract -Recurse -Filter 'esptool.exe' | Select-Object -First 1
if (-not $found) { throw "压缩包里没找到 esptool.exe" }

# 官方包是 onedir 结构（esptool.exe + _internal/），这里只取 exe 需要它自带依赖
Copy-Item $found.FullName $target -Force
Remove-Item $tmp -Force -ErrorAction SilentlyContinue
Remove-Item $extract -Recurse -Force -ErrorAction SilentlyContinue

Write-Output "完成: $target ($([math]::Round((Get-Item $target).Length/1KB,1)) KB)"
Write-Output '提示：若该 exe 依赖 _internal 目录，请改用 platformio 自带的独立版 esptool.exe'
