import QtQuick 2.5

Rectangle {
    color: "black"

    Image {
        id: artwork
        property int padding: 0
        width: parent.width - padding
        height: parent.height - padding
        fillMode: Image.PreserveAspectFit
        anchors.centerIn: parent
        source: "file://" + modelData
    }
}
