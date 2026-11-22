// Nox Home - one slanted (parallelogram) tile: background art + name.
import QtQuick

Item {
    id: tile

    property string name
    property string image
    property color tileColor: "#3c3489"
    property bool selected: false
    property real skew: 0.325 // tan(18 deg)

    signal clicked()

    // Shear the whole tile; children are sheared back so art and text stay upright.
    transform: Matrix4x4 {
        // top edge stays in place, bottom edge leans left: neighbours never overlap
        matrix: Qt.matrix4x4(1, -tile.skew, 0, 0,
                             0, 1, 0, 0,
                             0, 0, 1, 0,
                             0, 0, 0, 1)
    }

    Rectangle {
        id: frame
        anchors.fill: parent
        radius: 6
        color: tile.tileColor
        clip: true
        border.width: tile.selected ? 3 : 0
        border.color: "#cecbf6"

        Image {
            id: art
            visible: tile.image !== ""
            source: tile.image
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
            // Oversized and sheared back so it covers the whole parallelogram
            width: parent.width + tile.skew * parent.height
            height: parent.height
            x: -tile.skew * parent.height / 2
            sourceSize.width: 640
            transform: Matrix4x4 {
                matrix: Qt.matrix4x4(1, tile.skew, 0, -tile.skew * art.height / 2,
                                     0, 1, 0, 0,
                                     0, 0, 1, 0,
                                     0, 0, 0, 1)
            }
        }

        // Darken the bottom so the name stays readable on any image
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: parent.height * 0.45
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: "#99000000" }
            }
        }

        Text {
            text: tile.name
            color: "white"
            font.pixelSize: Math.max(12, tile.height * 0.12)
            font.weight: Font.Medium
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: tile.height * 0.12
            anchors.bottomMargin: tile.height * 0.08
            transform: Matrix4x4 {
                matrix: Qt.matrix4x4(1, tile.skew, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: tile.clicked()
    }
}
