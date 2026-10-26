# ESP32 Flasher

ESP32 烧录器 —— Qt 6 QML 写的图形界面，包一层 esptool。
**静态 Qt 编译，零第三方 DLL 依赖**，单文件即可运行。

![screenshot](docs/screenshot.png)

## 功能

- 串口自动枚举（PortLister）
- 烧录 / 擦除 / 读芯片信息
- 波特率可选 115200 ~ 921600
- 芯片类型选择（esp32 / esp32s3 / esp32c3 / esp32c6 …）
- 偏移量快捷选项（0x0 / 0x8000 / 0x10000 / 自定义）
- 内置串口监视器（实时查看 log）
- 拖放 .bin 文件直接烧录

## 下载

到 [Releases](https://github.com/louhui-hello/esp32-flasher/releases) 下载
`esp32flasher.exe`，双击运行，**不需要安装 Qt 或任何运行库**。

首次启动会在同一目录解出一个 `esptool.exe`（105 KB，内置在 exe 里）。

## 编译

### 依赖

| 组件 | 版本 |
|---|---|
| Qt | 6.12（Quick / QuickControls2 / SerialPort） |
| CMake | 3.21+ |
| 编译器 | MinGW 13.1（静态 Qt 也用这个） |

### 动态版（开发用）

```powershell
cmake -G Ninja -B build -DCMAKE_PREFIX_PATH=G:/lang/Qt/6.12.0/mingw_64
cmake --build build
cd build && windeployqt --release --qmldir ../qml esp32flasher.exe
```

### 静态版（发布用，单文件）

先编静态 Qt（一次性，约 1 小时）：

```powershell
.\configure.bat -static -static-runtime -release -platform win32-g++ ^
    -prefix G:\lang\Qt-static-6.12.0 -nomake examples -nomake tests ^
    -skip qtwebengine -skip qtquick3d -skip qtquick3dphysics -skip qtmultimedia
ninja -j16
ninja install
```

再编烧录器：

```powershell
.\scripts\fetch_esptool.ps1 -Version 5.6.0
cmake -G Ninja -B build-static -DCMAKE_BUILD_TYPE=Release ^
      -DCMAKE_PREFIX_PATH=G:\lang\Qt-static-6.12.0
cmake --build build-static
```

产物 `esp32flasher.exe` 约 105 MB，`objdump -p` 里只有 Windows 系统 DLL。

## 内嵌 esptool 的原理

```
tools/esptool.exe  →  qt_add_resources()  →  编进 exe 的 .rcc 段
首次启动           →  ensureBundledEsptool() 解出到 exe 同级目录
                   →  目录不可写时退回 %LOCALAPPDATA%
```

`tools/esptool.exe` 不进仓库（它是 esptool 的 GPL 二进制），
用 `scripts/fetch_esptool.ps1` 自动下载官方 release。

## 许可

本项目采用 **LGPL-3.0**，见 [LICENSE](LICENSE)。

Qt 亦为 LGPL-3.0。静态链接 LGPL 库时，本项目整体以 LGPL-3.0 发布，
因此满足"可重新链接"的要求（源码可获取、可自行重新编译）。

内嵌的 `esptool.exe` 来自 [espressif/esptool](https://github.com/espressif/esptool)，
遵循 GPL-2.0，作为独立程序通过命令行调用，不并入本程序。
