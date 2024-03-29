import QtQuick
import Box2D
import QtCore

import "../.."

ArtBoxBody {
    signal beyondThePale(var item)

    onYChanged: {
        if (y > root.height) {
            beyondThePale(this)
        }
    }

    density: 1.0
    friction: 0.0
    restitution: 0.0

    fixedRotation: true
    bodyType: Body.Dynamic
}
