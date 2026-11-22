// Nox Home - settings menu (keyboard: Up/Down, Enter, Escape).
// "Overlay de performance" is a switch: when on, its options unfold below it.
import QtQuick

Rectangle {
    id: panel

    property int currentIndex: 0
    readonly property var actions: [
        { type: "command", label: "Wi-Fi", command: "foot --title 'Nox - Wi-Fi' nox-wifi" },
        { type: "command", label: "Configurer la persistance", command: "foot --title 'Nox - Persistance' sudo nox-setup-home" },
        { type: "overlay", label: "Overlay de performance" },
        { type: "command", label: "Infos système", command: "foot --title 'Nox - Infos' sh -c 'nox-info; read -r -p \"Entree pour fermer\" _'" },
        { type: "command", label: "Terminal", command: "foot" },
        { type: "command", label: "Redémarrer", command: "systemctl reboot" },
        { type: "command", label: "Éteindre", command: "systemctl poweroff" }
    ]

    // Flat list shown on screen: overlay options are inserted after the switch.
    readonly property var rows: {
        const result = []
        for (const action of actions) {
            result.push(action)
            if (action.type === "overlay" && launcher.overlayEnabled) {
                for (const option of launcher.overlayOptions)
                    result.push({ type: "option", label: option.label, key: option.key, enabled: option.enabled })
            }
        }
        return result
    }

    signal closed()

    color: "#f512101f"
    focus: visible

    function activate(index) {
        const row = rows[index]
        if (row.type === "command")
            launcher.runTool(row.command)
        else if (row.type === "overlay")
            launcher.overlayEnabled = !launcher.overlayEnabled
        else if (row.type === "option")
            launcher.toggleOverlayOption(row.key)
    }

    onRowsChanged: currentIndex = Math.min(currentIndex, rows.length - 1)

    Keys.onUpPressed: currentIndex = (currentIndex + rows.length - 1) % rows.length
    Keys.onDownPressed: currentIndex = (currentIndex + 1) % rows.length
    Keys.onReturnPressed: activate(currentIndex)
    Keys.onEnterPressed: activate(currentIndex)
    Keys.onSpacePressed: activate(currentIndex)
    Keys.onEscapePressed: closed()
    Keys.onBackPressed: closed()

    MouseArea { anchors.fill: parent; onClicked: panel.closed() }

    Column {
        anchors.centerIn: parent
        spacing: panel.height * 0.007
        width: panel.width * 0.34

        Text {
            text: "Paramètres"
            color: "#eeedfe"
            font.pixelSize: panel.height * 0.036
            font.weight: Font.Medium
            bottomPadding: panel.height * 0.012
        }

        Repeater {
            model: panel.rows
            delegate: Rectangle {
                id: rowItem
                required property var modelData
                required property int index
                readonly property bool isOption: modelData.type === "option"
                readonly property bool isCurrent: index === panel.currentIndex

                // Options are indented and smaller: the unfolded "volet"
                x: isOption ? parent.width * 0.08 : 0
                width: parent.width - x
                height: panel.height * (isOption ? 0.036 : 0.05)
                radius: height / 2
                color: isCurrent ? "#eeedfe" : (isOption ? "#1d1a3a" : "#26215c")

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    x: parent.height * 0.5
                    text: rowItem.modelData.label
                    color: rowItem.isCurrent ? "#26215c" : "#eeedfe"
                    font.pixelSize: parent.height * 0.38
                }

                // Switch for the overlay row
                Rectangle {
                    visible: rowItem.modelData.type === "overlay"
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: parent.height * 0.4
                    width: parent.height * 0.9
                    height: parent.height * 0.5
                    radius: height / 2
                    color: launcher.overlayEnabled ? "#7f77dd" : "#5f5e5a"
                    Rectangle {
                        width: parent.height * 0.8
                        height: width
                        radius: width / 2
                        anchors.verticalCenter: parent.verticalCenter
                        x: launcher.overlayEnabled ? parent.width - width - parent.height * 0.1 : parent.height * 0.1
                        color: "#ffffff"
                        Behavior on x { NumberAnimation { duration: 120 } }
                    }
                }

                // Check box for overlay options
                Rectangle {
                    visible: rowItem.isOption
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: parent.height * 0.45
                    width: parent.height * 0.45
                    height: width
                    radius: width * 0.2
                    color: rowItem.modelData.enabled ? "#7f77dd" : "transparent"
                    border.width: 2
                    border.color: rowItem.isCurrent ? "#26215c" : "#afa9ec"
                    Text {
                        anchors.centerIn: parent
                        visible: rowItem.modelData.enabled === true
                        text: "✓"
                        color: "#ffffff"
                        font.pixelSize: parent.height * 0.8
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: panel.currentIndex = rowItem.index
                    onClicked: panel.activate(rowItem.index)
                }
            }
        }

        Text {
            text: "▲ ▼  choisir      Entrée  activer      Échap  retour"
            color: "#888399"
            font.pixelSize: panel.height * 0.018
            topPadding: panel.height * 0.02
        }
    }
}
