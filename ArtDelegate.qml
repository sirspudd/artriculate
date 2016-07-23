import QtQuick 2.5
import Box2D 2.0
import Qt.labs.settings 1.0

ImageBoxBody {
    id: picture

    property bool freefall: false

    onYChanged: freefall && ((y <= floor.y) || picture.destroy())

    density: 0.01
    friction: 1.0
    fixedRotation: parent.fixedRotation
    world: parent.physicsWorld
    bodyType: Body.Dynamic

    source: "file://" + imageModel.randomPicture()
}
