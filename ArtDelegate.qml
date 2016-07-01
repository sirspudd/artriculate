import QtQuick 2.5
import Box2D 2.0
import Qt.labs.settings 1.0

ImageBoxBody {
    id: picture

    function detonate() { settings.animateDeath ? destroyAnimation.start() : picture.destroy() }

    density: 0.01
    friction: 1.0
    fixedRotation: parent.fixedRotation
    world: parent.physicsWorld
    bodyType: Body.Dynamic

    source: "file://" + imageModel.randomPicture()

    SequentialAnimation {
        id: destroyAnimation
        NumberAnimation { target: picture; property: "height"; to: 0; duration: 1000 }
        ScriptAction { script: { picture.destroy(); } }
    }
}
