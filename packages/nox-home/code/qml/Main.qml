// Nox Home - console-style home screen (PS5-like row of slanted tiles).
import QtQuick
import QtQuick.Window

Window {
    id: root

    readonly property real unit: height / 1080 // layout scales with screen height
    readonly property var apps: launcher.apps
    property int currentIndex: 0
    readonly property var currentApp: apps.length > 0 ? apps[currentIndex] : ({})

    title: "Nox Home"
    color: "#12101f"
    visibility: Window.FullScreen

    function activate(index) {
        if (index < 0 || index >= apps.length)
            return
        currentIndex = index
        if (apps[index].kind === "settings")
            settings.visible = true
        else
            launcher.launch(index)
    }

    Connections {
        target: launcher
        function onLaunchFailed(name) {
            toast.text = "Impossible de lancer " + name
            toast.opacity = 1
            toastTimer.restart()
        }
    }

    // ---- Top bar --------------------------------------------------------
    Row {
        x: 64 * root.unit
        y: 40 * root.unit
        spacing: 14 * root.unit
        Rectangle {
            width: 14 * root.unit; height: width; radius: width / 2
            color: "#afa9ec"
            anchors.verticalCenter: parent.verticalCenter
        }
        Text { text: "Nox"; color: "#eeedfe"; font.pixelSize: 30 * root.unit; font.weight: Font.Medium }
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: 64 * root.unit
        y: 44 * root.unit
        spacing: 28 * root.unit
        // Network signal: 4 bars (wired = full), dimmed when offline
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4 * root.unit
            Repeater {
                model: 4
                delegate: Rectangle {
                    required property int index
                    width: 6 * root.unit
                    height: (8 + index * 6) * root.unit
                    radius: 1.5 * root.unit
                    anchors.bottom: parent.bottom
                    color: index < launcher.signalBars ? "#eeedfe" : "#3c3a52"
                }
            }
        }
        Text {
            id: clock
            color: "#a9a4cf"
            font.pixelSize: 22 * root.unit
            text: Qt.formatTime(new Date(), "HH:mm")
            Timer {
                interval: 10000; repeat: true; running: root.visible
                onTriggered: clock.text = Qt.formatTime(new Date(), "HH:mm")
            }
        }
    }

    // ---- Tile row -------------------------------------------------------
    ListView {
        id: row
        x: 96 * root.unit
        y: 190 * root.unit
        width: root.width - x
        height: 300 * root.unit
        orientation: ListView.Horizontal
        spacing: 28 * root.unit
        interactive: false
        model: root.apps
        currentIndex: root.currentIndex
        highlightFollowsCurrentItem: true
        preferredHighlightBegin: 0
        preferredHighlightEnd: width * 0.35
        highlightRangeMode: ListView.ApplyRange
        highlightMoveDuration: 180
        focus: !settings.visible

        delegate: Tile {
            required property var modelData
            required property int index
            readonly property bool isCurrent: index === root.currentIndex
            width: (isCurrent ? 330 : 190) * root.unit
            height: (isCurrent ? 230 : 132) * root.unit
            name: modelData.name
            image: modelData.image
            tileColor: modelData.color
            selected: isCurrent
            Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            onClicked: {
                if (root.currentIndex === index)
                    root.activate(index)
                else
                    root.currentIndex = index
            }
        }

        Keys.onLeftPressed: root.currentIndex = Math.max(0, root.currentIndex - 1)
        Keys.onRightPressed: root.currentIndex = Math.min(root.apps.length - 1, root.currentIndex + 1)
        Keys.onReturnPressed: root.activate(root.currentIndex)
        Keys.onEnterPressed: root.activate(root.currentIndex)
        Keys.onSpacePressed: root.activate(root.currentIndex)
    }

    // ---- Details of the selected app -------------------------------------
    Column {
        x: 96 * root.unit
        y: 560 * root.unit
        spacing: 10 * root.unit

        Text {
            text: root.currentApp.name || ""
            color: "#eeedfe"
            font.pixelSize: 44 * root.unit
            font.weight: Font.Medium
        }
        Text {
            text: root.currentApp.subtitle || ""
            color: "#a9a4cf"
            font.pixelSize: 22 * root.unit
        }
        Item { width: 1; height: 16 * root.unit }
        Rectangle {
            width: actionLabel.implicitWidth + 64 * root.unit
            height: 56 * root.unit
            radius: height / 2
            color: playArea.containsMouse ? "#ffffff" : "#eeedfe"
            Text {
                id: actionLabel
                anchors.centerIn: parent
                text: (root.currentApp.action || "Jouer")
                color: "#26215c"
                font.pixelSize: 22 * root.unit
                font.weight: Font.Medium
            }
            MouseArea {
                id: playArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.activate(root.currentIndex)
            }
        }
    }

    // ---- Key hints --------------------------------------------------------
    Text {
        x: 96 * root.unit
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 44 * root.unit
        text: "◀ ▶  choisir      Entrée  lancer      Touche Windows  revenir ici"
        color: "#888399"
        font.pixelSize: 18 * root.unit
    }

    // ---- Storage (bottom right) -----------------------------------------
    Column {
        anchors.right: parent.right
        anchors.rightMargin: 64 * root.unit
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 44 * root.unit
        spacing: 6 * root.unit
        Repeater {
            model: launcher.storage
            delegate: Text {
                required property string modelData
                anchors.right: parent.right
                text: modelData
                color: "#a9a4cf"
                font.pixelSize: 18 * root.unit
                font.family: "DejaVu Sans Mono"
            }
        }
    }

    Text {
        id: toast
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 110 * root.unit
        color: "#f09595"
        font.pixelSize: 22 * root.unit
        opacity: 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        Timer { id: toastTimer; interval: 3000; onTriggered: toast.opacity = 0 }
    }

    SettingsPanel {
        id: settings
        anchors.fill: parent
        visible: false
        onVisibleChanged: if (visible) forceActiveFocus(); else row.forceActiveFocus()
        onClosed: visible = false
    }

    Component.onCompleted: row.forceActiveFocus()
}
