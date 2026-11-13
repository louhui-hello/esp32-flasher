# SPDX-License-Identifier: GPL-3.0-only
get_target_property(_espflasher_qt_type Qt6::Core TYPE)
if(NOT _espflasher_qt_type STREQUAL "STATIC_LIBRARY")
    message(FATAL_ERROR "ESPFLASHER_STATIC_QT requires a static Qt installation")
endif()

# Register only the platform, image and QML plugins used by the application.
set(_espflasher_gui_plugins
    QWindowsIntegrationPlugin QOffscreenIntegrationPlugin
    QGifPlugin QICOPlugin QJpegPlugin QSvgPlugin QSvgIconPlugin QWebpPlugin)
foreach(plugin IN LISTS _espflasher_gui_plugins)
    find_package(Qt6${plugin} CONFIG REQUIRED
        PATHS "${Qt6_DIR}/../Qt6Gui" NO_DEFAULT_PATH)
endforeach()

# Base modules must be loaded before styles and dialogs that depend on them.
set(_espflasher_qml_plugins
    modelsplugin workerscriptplugin qmlplugin qtquick2plugin quickwindow
    qquicklayoutsplugin qtquicktemplates2plugin qtquickcontrols2implplugin
    qtquickcontrols2plugin qtquickcontrols2basicstyleimplplugin
    qtquickcontrols2basicstyleplugin qtquickcontrols2fusionstyleimplplugin
    qtquickcontrols2fusionstyleplugin qtquicknativestyleplugin
    qtquickcontrols2windowsstyleimplplugin qtquickcontrols2windowsstyleplugin
    qtquickdialogs2quickimplplugin qtquickdialogsplugin
    qmlshapesplugin qmlfolderlistmodelplugin effectsplugin)
foreach(plugin IN LISTS _espflasher_qml_plugins)
    find_package(Qt6${plugin} CONFIG REQUIRED
        PATHS "${Qt6_DIR}/../Qt6Qml/QmlPlugins" NO_DEFAULT_PATH)
endforeach()

function(espflasher_link_static_plugins target)
    set(imports "#include <QtPlugin>\n")
    foreach(plugin IN LISTS _espflasher_gui_plugins _espflasher_qml_plugins)
        get_target_property(plugin_class Qt6::${plugin} QT_PLUGIN_CLASS_NAME)
        string(APPEND imports "Q_IMPORT_PLUGIN(${plugin_class})\n")
        target_link_libraries(${target} PRIVATE Qt6::${plugin})
    endforeach()
    set(import_file "${CMAKE_CURRENT_BINARY_DIR}/${target}_static_plugins.cpp")
    file(WRITE "${import_file}" "${imports}")
    target_sources(${target} PRIVATE "${import_file}")
endfunction()
