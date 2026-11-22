// Nox Home - settings menu (keyboard: Up/Down, Enter, Escape).
import QtQuick

Rectangle {
    id: panel

    property int currentIndex: 0
    readonly property var entries: [
        { label: "Wi-Fi", command: "foot --title 'Nox - Wi-Fi' nox-wifi" },
        { label: "Configurer la persistance", command: "foot --title 'Nox - Persistance' sudo nox-setup-home" },
        { label: "Infos système", command: "foot --title 'Nox - Infos' sh -c 'nox-info; read -r -p \"Entree pour fermer\" _'" },
        { label: "Terminal", command: "foot" },
        { label: "Redémarrer", command: "systemctl reboot" },
        { label: "Éteindre", command: "systemctl poweroff" }
    ]

    signal closed()

    color: "#f512101f"
    focus: visible

    function activate(index) {
        launcher.runTool(entries[index].command)
    }

    Keys.onUpPressed: currentIndex = (currentIndex + entries.length - 1) % entries.length
    Keys.onDownPressed: currentIndex = (currentIndex + 1) % entries.length
    Keys.onReturnPressed: activate(currentIndex)
    Keys.onEnterPressed: activate(currentIndex)
    Keys.onEscapePressed: closed()
    Keys.onBackPressed: closed()

    MouseArea { anchors.fill: parent; onClicked: panel.closed() }

    Column {
        anchors.centerIn: parent
        spacing: panel.height * 0.012
        width: panel.width * 0.32

        Text {
            text: "Paramètres"
            color: "#eeedfe"
            font.pixelSize: panel.height * 0.04
            font.weight: Font.Medium
            bottomPadding: panel.height * 0.02
        }

        Repeater {
            model: panel.entries
            delegate: Rectangle {
                required property var modelData
                required property int index
                width: parent.width
                height: panel.height * 0.06
                radius: height / 2
                color: index === panel.currentIndex ? "#eeedfe" : "#26215c"

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    x: parent.height * 0.5
                    text: modelData.label
                    color: index === panel.currentIndex ? "#26215c" : "#eeedfe"
                    font.pixelSize: parent.height * 0.36
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: panel.currentIndex = index
                    onClicked: panel.activate(index)
                }
            }
        }

        Text {
            text: "Échap  retour"
            color: "#888399"
            font.pixelSize: panel.height * 0.018
            topPadding: panel.height * 0.02
        }
    }
}
