import QtQuick 2.6

// Required for effortless web serving!
import ".."

Item {
    width: infoContent.width
    height: infoContent.height

    clip: false
    visible: nativeUtils.displayMetadata

    QtObject {
        id: d
        property double floatTravelLimit: 4
        property double floatTravelInterval: 4000
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.2
    }

    Item {
        id: infoContent
        width: childrenRect.width
        height: childrenRect.height

        SequentialAnimation on x {
            loops: Animation.Infinite
            PropertyAnimation { to: d.floatTravelLimit; duration: d.floatTravelInterval }
            PropertyAnimation { to: -d.floatTravelLimit; duration: d.floatTravelInterval }
        }
        SequentialAnimation on y {
            loops: Animation.Infinite
            PropertyAnimation { to: d.floatTravelLimit; duration: d.floatTravelInterval*1.6  }
            PropertyAnimation { to: -d.floatTravelLimit; duration: d.floatTravelInterval*1.6  }
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
}
