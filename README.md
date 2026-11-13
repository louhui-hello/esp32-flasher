# ESP32 Flasher

基于 Qt 6 / QML 的 ESP32 图形烧录器，通过独立的 esptool 进程执行芯片操作。

## 功能

- 自动枚举串口，支持 ESP32-S3、ESP32-S2、ESP32-C3、ESP32、ESP8266。
- 烧录固件、擦除 Flash、读取芯片信息，显示 esptool 输出和进度。
- 支持拖放 `.bin` 文件，烧录偏移可选 0x0 / 0x10000。
- 串口监视、文本发送及 Hex 显示；烧录前关闭串口监视。
- 提供 LLVM-MinGW + 静态 Qt 的 Windows x64 Release 构建。

## 下载与运行

从 [Releases](https://github.com/louhui-hello/esp32-flasher/releases) 下载发布包，解压后运行 `esp32flasher.exe`。
标准便携版需要保留同目录的 `esptool.exe`。Qt 库已静态链接，esptool 内含 Python，运行时无需安装 Qt、Python 或激活 venv。

选择串口、芯片、固件及正确的烧录偏移，再开始烧录。固件的分区和偏移必须与目标设备对应。
构建验证不包含真机擦除或烧录。

## LLVM 静态构建

依赖：PowerShell、CMake 3.21+、Ninja、LLVM-MinGW、与其 ABI 匹配的静态 Qt，以及 Python 3.11。
Qt 模块需要 Quick、QuickControls2、SerialPort、Svg 和对应的 QML 插件。
本次构建使用 Clang 22.1.7、Qt 6.12.0、UCRT、Windows x86_64。

```powershell
.uild-llvm-static.ps1
```

脚本的默认路径对应本机安装；其他机器可使用 `-QtPrefix`、`-CompilerBin`、`-CMake`、`-Ninja`、`-Python` 指定工具位置。
构建目录为 `build/llvm-static`，发布目录为 `dist/llvm-static`。

Python 依赖只安装在 `build/esptool-venv`，版本锁定于 `packaging/esptool-requirements.txt`。
`package-esptool.ps1` 使用 PyInstaller 生成独立后端，不修改全局 Python 包。

### 可选内嵌后端

```powershell
.uild-llvm-static.ps1 -BundleEsptool
```

启用后，esptool 会作为 Qt 资源编入程序，首次运行解出到程序目录；目录不可写时使用用户数据目录。
CMake 选项为 `ESPFLASHER_BUNDLE_ESPTOOL=ON`。默认关闭，使用两个 EXE 的便携布局。

### 常规动态 Qt 构建

```powershell
cmake -S . -B build/dynamic -G Ninja -DCMAKE_PREFIX_PATH=/path/to/Qt
cmake --build build/dynamic --parallel
# 使用对应 Qt 的 windeployqt，QML 路径为 ./qml
```

## 项目结构

- `src/`：esptool 调用、串口监视和端口枚举。
- `qml/`：用户界面。
- `cmake/StaticQt.cmake`：静态 Qt 插件配置。
- `packaging/`：Python 入口和固定版本依赖。
- `build-llvm-static.ps1`：LLVM 构建与发布目录生成。
- `package-esptool.ps1`：venv 与 PyInstaller 后端打包。

## 许可证

本仓库的应用代码采用 **GNU GPL v3.0（GPL-3.0-only）**，见 [LICENSE](LICENSE)。
本次提交起使用该许可证；已发布的旧版本保留其原有许可。

Qt、esptool、Python、PyInstaller 及其依赖保留各自版权和许可证。
其中 esptool 为 GPL-2.0-or-later，作为独立进程调用。
第三方来源、版本和构建方式见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。
