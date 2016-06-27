import QtQuick 2.5
import QtQuick.Window 2.2

Window {
    id: root
    visible: true
    width: 1024
    height: 768

    ListView {
        id: view
        clip: true
        snapMode: ListView.SnapToItem
        orientation: ListView.Horizontal
        anchors.fill: parent
        delegate: Rectangle {
            color: "black"
            width: view.width
            height: view.height
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
        onWidthChanged: {
            view.model = imageModel
        }
    }
}
