import QtQuick 2.5
import Box2D 2.0
import QtCore

import "../.."

ArtBoxBody {
    id: picture

    signal beyondThePale(var item)

    onYChanged: {
        if (y > globalFloor.y) {
            beyondThePale(this)
        }
    }

    density: wellSettings.density
    friction: wellSettings.friction
    restitution: wellSettings.restitution

    fixedRotation: wellSettings.fixedRotation
    bodyType: Body.Dynamic
}
