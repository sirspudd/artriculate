import QtQuick 2.5
import Box2D 2.0
import Qt.labs.settings 1.0

ImageBoxBody {
    id: picture

    onYChanged: y > floor.y && picture.destroy()

    density: 1.0
    friction: 0.0
    fixedRotation: parent.fixedRotation
    world: parent.physicsWorld
    bodyType: Body.Dynamic

    source: imageModel.randomPicture()
}
