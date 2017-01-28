import QtQuick 2.5
import Box2D 2.0
import Qt.labs.settings 1.0

import ".."

ArtBoxBody {
    signal beyondThePale(var item)

    onYChanged: {
        if (y > root.height) {
            beyondThePale(this)
        }
    }

    density: 1
    friction: 1.0
    restitution: 0.0

    fixedRotation: true
    bodyType: Body.Dynamic
}
