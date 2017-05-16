import QtQuick 2.6

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
