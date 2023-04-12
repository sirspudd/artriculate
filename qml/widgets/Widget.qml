import QtQuick

// Required for effortless web serving!
import ".."

Item {
    width: childrenRect.width
    height: childrenRect.height

    property alias text: label.text

    Text {
        id: label
        font.pixelSize: 40
        font.bold: true
        color: "white"
    }
}
