# SPDX-License-Identifier: GPL-3.0-only
cmake_minimum_required(VERSION 3.21)
project(esp32flasher LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

option(ESPFLASHER_STATIC_QT "Link against a static Qt installation" OFF)
if(ESPFLASHER_STATIC_QT)
    set(QT_SKIP_AUTO_PLUGIN_INCLUSION ON)
    set(QT_SKIP_AUTO_QML_PLUGIN_INCLUSION ON)
endif()

find_package(Qt6 REQUIRED COMPONENTS Quick QuickControls2 SerialPort)
if(ESPFLASHER_STATIC_QT)
    find_package(Qt6 REQUIRED COMPONENTS Svg)
    include(cmake/StaticQt.cmake)
endif()

qt_standard_project_setup(REQUIRES 6.5)
if(Qt6_VERSION VERSION_GREATER_EQUAL 6.8)
    qt_policy(SET QTP0004 NEW)
endif()

qt_add_executable(esp32flasher
    main.cpp
    src/esptoolrunner.cpp
    src/esptoolrunner.h
    src/serialmonitor.cpp
    src/serialmonitor.h
    src/portlister.cpp
    src/portlister.h
)

option(ESPFLASHER_BUNDLE_ESPTOOL "Embed the standalone esptool backend" OFF)
if(ESPFLASHER_BUNDLE_ESPTOOL)
    if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/tools/esptool.exe")
        message(FATAL_ERROR "Run package-esptool.ps1 before enabling ESPFLASHER_BUNDLE_ESPTOOL")
    endif()
    qt_add_resources(esp32flasher "esptool_resources"
        PREFIX "/"
        FILES tools/esptool.exe)
    target_compile_definitions(esp32flasher PRIVATE ESPFLASHER_BUNDLE_ESPTOOL)
endif()

set(_espflasher_qml_options)
if(ESPFLASHER_STATIC_QT)
    list(APPEND _espflasher_qml_options NO_IMPORT_SCAN)
endif()

qt_add_qml_module(esp32flasher
    ${_espflasher_qml_options}
    URI EspFlasher
    VERSION 1.0
    QML_FILES
        qml/Main.qml
)

target_link_libraries(esp32flasher PRIVATE
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::SerialPort
)

if(ESPFLASHER_STATIC_QT)
    espflasher_link_static_plugins(esp32flasher)
endif()

# Windows 下不弹控制台窗口
if(WIN32)
    set_target_properties(esp32flasher PROPERTIES WIN32_EXECUTABLE TRUE)
endif()
