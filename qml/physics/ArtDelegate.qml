import QtQuick 2.5
import Box2D 2.0
import Qt.labs.settings 1.0

ImageBoxBody {
    id: picture

    signal beyondThePale(var item)
    property var effect

    onYChanged: {
        if (y > globalFloor.y) {
            beyondThePale(this)
        }
    }

    density: 1.0
    friction: 0
    restitution: physicsSettings.restitution

    fixedRotation: physicsSettings.fixedRotation
    bodyType: Body.Dynamic
}
