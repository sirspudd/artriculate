import QtQuick

// Required for effortless web serving!

Item {
    width: infoContent.width
    height: infoContent.height

    clip: false
    visible: nativeUtils.displayMetadata

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.2
    }

    Item {
        id: infoContent
        width: childrenRect.width
        height: childrenRect.height

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
}
