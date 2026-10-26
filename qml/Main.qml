import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import EspFlasher 1.0

ApplicationWindow {
    id: win
    width: 940
    height: 760
    visible: true
    title: "ESP32 烧录器 · github.com/louhui-hello/ESP32-S3_Clock"
    color: "#f2f3f5"

    PortLister    { id: lister }
    EsptoolRunner { id: runner }
    SerialMonitor { id: serial }

    property string firmwarePath: ""
    property bool   hexMode: false
    property bool   monitorWasOpen: false

    // ── 明色主题 ──
    readonly property color bg:      "#f2f3f5"
    readonly property color panel:   "#ffffff"
    readonly property color border:  "#d0d3d8"
    readonly property color textPri: "#1f2328"
    readonly property color textDim: "#6b7280"
    readonly property color accent:  "#0a66c2"
    readonly property color ok:      "#0f7b0f"
    readonly property color warn:    "#a15c00"
    readonly property color err:     "#c42b1c"
    readonly property color mono:    "#24292f"
    readonly property color monoBg:  "#fbfbfc"

    function toHex(str) {
        let out = ""
        for (let i = 0; i < str.length; i++) {
            const c = str.charCodeAt(i).toString(16).toUpperCase()
            out += (c.length === 1 ? "0" + c : c) + " "
        }
        return out.trim()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        // ── 标题 ──
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "ESP32 烧录器"
                color: win.textPri
                font.pixelSize: 20
                font.bold: true
            }
            Text {
                text: "· github.com/louhui-hello/ESP32-S3_Clock"
                color: win.accent
                font.pixelSize: 13
                font.underline: true
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Qt.openUrlExternally("https://github.com/louhui-hello/ESP32-S3_Clock")
                }
            }
            Item { Layout.fillWidth: true }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: win.border }

        // ── 第一行：串口 / 波特率 / 芯片 / 偏移 ──
        GridLayout {
            Layout.fillWidth: true
            columns: 8
            rowSpacing: 8
            columnSpacing: 10

            Text { text: "串口"; color: win.textDim }
            ComboBox { id: portBox; Layout.preferredWidth: 190; model: [] }
            Button {
                text: "刷新"
                Layout.minimumWidth: 70
                onClicked: {
                    const list = lister.ports()
                    portBox.model = list
                    if (list.length > 0) portBox.currentIndex = 0
                }
            }

            Text { text: "波特率"; color: win.textDim }
            ComboBox {
                id: baudBox
                Layout.preferredWidth: 120
                model: ["115200", "230400", "460800", "921600"]
                currentIndex: 2
            }

            Text { text: "芯片"; color: win.textDim }
            ComboBox {
                id: chipBox
                Layout.preferredWidth: 150
                model: ["esp32s3", "esp32s2", "esp32c3", "esp32", "esp8266"]
                onCurrentTextChanged: runner.chip = currentText
            }

            Item { Layout.fillWidth: true }

            Text { text: "偏移"; color: win.textDim }
            ComboBox {
                id: offsetBox
                Layout.preferredWidth: 110
                model: ["0x0", "0x10000"]
            }
        }

        // ── 固件 ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Text { text: "固件"; color: win.textDim }
            Rectangle {
                Layout.fillWidth: true
                height: 34
                color: win.panel
                border.color: dropArea.containsDrag ? win.accent : win.border
                border.width: dropArea.containsDrag ? 2 : 1
                radius: 4
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 20
                    text: win.firmwarePath === "" ? "把 .bin 拖到这里，或点右侧浏览" : win.firmwarePath
                    color: win.firmwarePath === "" ? win.textDim : win.textPri
                    elide: Text.ElideMiddle
                }
            }
            Button { text: "浏览..."; Layout.minimumWidth: 90; onClicked: fileDialog.open() }
        }

        // ── esptool ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Text { text: "esptool"; color: win.textDim }
            TextField {
                id: esptoolField
                Layout.fillWidth: true
                placeholderText: "esptool.exe 路径（留空则用程序同目录）"
                color: win.textPri
                onTextChanged: runner.esptoolPath = text
                background: Rectangle { color: win.panel; border.color: win.border; radius: 4 }
            }
            Button { text: "浏览..."; Layout.minimumWidth: 90; onClicked: esptoolDialog.open() }
        }

        // ── 操作按钮 ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Button {
                text: runner.busy ? "烧录中..." : "↓ 开始烧录"
                enabled: !runner.busy && win.firmwarePath !== "" && portBox.currentText !== ""
                Layout.preferredHeight: 40
                Layout.minimumWidth: 150
                onClicked: {
                    win.monitorWasOpen = serial.opened
                    serial.close()
                    logArea.append("=== 开始烧录 ===")
                    runner.flash(portBox.currentText, parseInt(baudBox.currentText),
                                 win.firmwarePath, offsetBox.currentText)
                }
            }
            Button {
                text: "擦除 Flash"
                enabled: !runner.busy
                Layout.preferredHeight: 40
                Layout.minimumWidth: 120
                onClicked: { serial.close(); logArea.append("=== 擦除 Flash ==="); runner.erase(portBox.currentText) }
            }
            Button {
                text: "读芯片"
                enabled: !runner.busy
                Layout.preferredHeight: 40
                Layout.minimumWidth: 100
                onClicked: { serial.close(); runner.chipInfo(portBox.currentText) }
            }
            Button {
                text: "中止"
                enabled: runner.busy
                Layout.preferredHeight: 40
                Layout.minimumWidth: 90
                onClicked: runner.abort()
            }

            Item { Layout.fillWidth: true }
            Text {
                text: runner.busy ? ("进度 " + runner.progress + "%") : "就绪"
                color: runner.busy ? win.warn : win.textDim
            }
        }

        ProgressBar {
            Layout.fillWidth: true
            from: 0; to: 100
            value: runner.progress
            visible: runner.busy || runner.progress > 0
        }

        // ── 日志区（自动滚动） ──
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 220
            color: win.monoBg
            border.color: win.border
            radius: 4

            ScrollView {
                id: logScroll
                anchors.fill: parent
                anchors.margins: 2
                clip: true

                TextArea {
                    id: logArea
                    readOnly: true
                    width: logScroll.availableWidth
                    color: win.mono
                    font.family: "Consolas"
                    font.pixelSize: 12
                    wrapMode: TextArea.WrapAtWordBoundaryOrAnywhere
                    background: null
                    onTextChanged: Qt.callLater(function() {
                        logScroll.contentItem.contentY =
                            Math.max(0, logScroll.contentItem.contentHeight - logScroll.height)
                    })
                }
            }
        }

        // ── 串口监视 ──
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 210
            color: win.panel
            border.color: win.border
            radius: 4

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text { text: "串口监视"; color: win.textDim; font.bold: true }

                    Button {
                        text: serial.opened ? "关闭" : "打开"
                        Layout.minimumWidth: 80
                        onClicked: {
                            if (serial.opened) serial.close()
                            else serial.open(portBox.currentText, parseInt(monitorBaudBox.currentText))
                        }
                    }
                    Text { text: "波特率"; color: win.textDim }
                    ComboBox {
                        id: monitorBaudBox
                        Layout.preferredWidth: 110
                        model: ["9600", "19200", "38400", "57600", "74880", "115200", "230400", "460800"]
                        currentIndex: 5
                    }
                    Button {
                        text: "清空"
                        Layout.minimumWidth: 80
                        onClicked: serialArea.text = ""
                    }
                    CheckBox {
                        text: "Hex"
                        onClicked: win.hexMode = checked
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: serial.opened ? ("已连接 " + serial.portName) : "未连接"
                        color: serial.opened ? win.ok : win.textDim
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: win.monoBg
                    border.color: win.border
                    radius: 4

                    ScrollView {
                        id: serialScroll
                        anchors.fill: parent
                        anchors.margins: 2
                        clip: true

                        TextArea {
                            id: serialArea
                            readOnly: true
                            width: serialScroll.availableWidth
                            color: win.mono
                            font.family: "Consolas"
                            font.pixelSize: 12
                            wrapMode: TextArea.WrapAtWordBoundaryOrAnywhere
                            background: null
                            onTextChanged: Qt.callLater(function() {
                                serialScroll.contentItem.contentY =
                                    Math.max(0, serialScroll.contentItem.contentHeight - serialScroll.height)
                            })
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    TextField {
                        id: sendField
                        Layout.fillWidth: true
                        placeholderText: "输入要发送的内容，回车发送"
                        color: win.textPri
                        background: Rectangle { color: win.monoBg; border.color: win.border; radius: 4 }
                        onAccepted: sendBtn.onClicked()
                    }
                    Button {
                        id: sendBtn
                        text: "发送"
                        Layout.minimumWidth: 90
                        onClicked: {
                            serial.sendLine(sendField.text)
                            serialArea.append("> " + sendField.text)
                            sendField.text = ""
                        }
                    }
                }
            }
        }
    }

    FileDialog {
        id: fileDialog
        title: "选择固件"
        nameFilters: ["固件 (*.bin)", "所有文件 (*)"]
        onAccepted: win.firmwarePath = selectedFile.toString().replace("file:///", "")
    }
    FileDialog {
        id: esptoolDialog
        title: "选择 esptool.exe"
        nameFilters: ["可执行文件 (*.exe)", "所有文件 (*)"]
        onAccepted: esptoolField.text = selectedFile.toString().replace("file:///", "")
    }

    DropArea {
        id: dropArea
        anchors.fill: parent
        onDropped: (drop) => {
            if (drop.hasUrls && drop.urls.length > 0) {
                const p = drop.urls[0].toString().replace("file:///", "")
                if (p.endsWith(".bin")) { win.firmwarePath = p; logArea.append("已选择固件: " + p) }
            }
        }
    }

    Connections {
        target: runner
        function onLog(line) { logArea.append(line) }
        function onFinished(ok, m) {
            logArea.append("=== " + (ok ? "✓ " : "✗ ") + m + " ===")
            // 烧录前监视器开着的话，烧完自动重开
            if (ok && win.monitorWasOpen) {
                serial.open(portBox.currentText, parseInt(monitorBaudBox.currentText))
                win.monitorWasOpen = false
            }
        }
    }
    Connections {
        target: serial
        function onReceived(t) { serialArea.append(win.hexMode ? win.toHex(t) : t) }
        function onError(msg) { logArea.append("串口错误: " + msg) }
    }

    Component.onCompleted: {
        // 把 C++ 自动探测到的 esptool 路径显示出来
        if (runner.esptoolPath !== "")
            esptoolField.text = runner.esptoolPath
        const list = lister.ports()
        portBox.model = list
        if (list.length > 0) portBox.currentIndex = 0
        logArea.append("就绪。请选择固件后点【开始烧录】。")
        logArea.append("提示：烧录时串口监视器会自动关闭。")
    }
}
