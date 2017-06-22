import QtQuick 2.0

import "../.."

ArtImage {
    id: root

    property bool reviewed: false

    function bowOut() {
        deathBow.start()
    }

    transform: Rotation {
        id: evilAxis
        origin.x: root.width/2
        origin.y: root.height
        axis { x: 1; y: 0; z: 0 }
    }
    SequentialAnimation {
        id: deathBow
//        PropertyAction {
//            target: root
//            property: "z"
//            value: root.z + 1
//        }
        NumberAnimation {
            easing.type: "InQuad"
            target: evilAxis
            property: "angle"
            from: 0
            to: 90
            duration: 3000
        }
        PropertyAction {
            target: root
            property: "visible"
            value: false
        }
    }
}
