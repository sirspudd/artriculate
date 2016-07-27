import QtQuick 2.5
import Box2D 2.0
import Qt.labs.settings 1.0

ImageBoxBody {
    id: picture

    signal beyondThePale(var item)

    onYChanged:
        if (y > floor.y)
            beyondThePale(this)

    density: 10
    friction: 0
    restitution: 0.2

    fixedRotation: parent.fixedRotation
    world: parent.physicsWorld
    bodyType: Body.Dynamic

    source: imageModel.randomPicture()
}
