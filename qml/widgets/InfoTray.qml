import QtQuick 2.6

Item {
    width: childrenRect.width
    height: childrenRect.height

    Rectangle {
        anchors.fill: parent
        opacity: 0.5
        color: "black"
    }

    Row {
        spacing: 10.0
        Resolution {
        }
        ItemCount {
        }
        FPS {
        }
        CollectionSize {
        }
    }
}
