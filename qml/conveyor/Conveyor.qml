import QtQuick 2.7
import Box2D 2.0
import Qt.labs.settings 1.0
import PictureModel 1.0

import ".."

Item {
    id: root

    anchors.fill: parent
    property var pictureArray: []
    property var nextImage

    ImageBoxBody {
        id: foot
        world: theWorld
        density: 20000
        bodyType: Body.Dynamic
        x: -width
        anchors.verticalCenter: viewport.verticalCenter
        rotation: -90
        mirror: true
        fixedRotation: true
        z: 10
        source: "qrc:/Monty_python_foot.png"
        sourceSize.height: viewport.height
        sourceSize.width: viewport.height/foot.implicitHeight*foot.implicitWidth
        Behavior on x { SmoothedAnimation{ duration: conveyorSettings.footAnimationTime } }
        Component.onCompleted: {
            foot.body.gravityScale = 0
        }
    }

    SequentialAnimation {
        id: stomp
        running: false
        ScriptAction { script: foot.x = pictureArray[pictureArray.length-1].x*1.1 }
        NumberAnimation { duration: conveyorSettings.footAnimationTime }
        // linger
        NumberAnimation { duration: 2*conveyorSettings.footAnimationTime }
        ScriptAction { script: foot.x = -foot.width - 10 }
        NumberAnimation { duration: conveyorSettings.footAnimationTime }
    }

    function spawnImage() {
        if (stomp.running)
            return

        if (!nextImage) {
            nextImage = imageDelegate.createObject(viewport, { y: -10000 });
        }

        if (pictureArray.length > 0 && pictureArray[pictureArray.length-1].x < nextImage.width) {
            var body = pictureArray[pictureArray.length-1].body
            if (body.linearVelocity.y < 0.001) {
                stomp.start()
            }
        } else {
            nextImage.murder.connect(removeImage)
            nextImage.y = -nextImage.height
            nextImage.world = theWorld

            pictureArray.push(nextImage)
            nextImage = null
        }
    }

    function removeImage(image)
    {
        pictureArray.splice(pictureArray.indexOf(image),1)
        image.destroy()
    }

    Settings {
        id: conveyorSettings
        category: "Conveyor"

        property int rowCount: 6
        property int footAnimationTime: 500
    }

    Component {
        id: imageDelegate
        ArtBoxBody {
            signal murder(var item)

            density: 1
            height: root.height/conveyorSettings.rowCount
            width: height*imageModel.data(modelIndex, PictureModel.RatioRole)
            bodyType: Body.Dynamic
            fixedRotation: true

            onXChanged: {
                if (x < 0) {
                    murder(this)
                } else if (x + width > floor.width) {
                    fixedRotation = false
                }
            }

            onYChanged: {
                if (y > viewport.height) {
                    murder(this)
                }
            }
        }
    }

    Item {
        id: viewport

        width: root.width*conveyorSettings.rowCount
        height: root.height/conveyorSettings.rowCount

        World {
            id: theWorld
            running: true
            timeStep: 1/20
        }

        DebugDraw {
            world: theWorld
            anchors.fill: parent
            visible: false
            enabled: visible
        }

        RectangleBoxBody {
            id: floor
            world: theWorld
            height: 0
            width: parent.width - 400
            anchors {
                top: parent.bottom
            }
            friction: 0
        }
    }

    Timer {
        id: feedTimer
        repeat: true
        running: true
        interval: 100
        onTriggered: {
            spawnImage()
        }
    }

    ShaderEffectSource {
        id: viewportTexture
        sourceItem: viewport
        width: viewport.width
        height: viewport.height
    }

    ShaderEffect {
        anchors.fill: parent
        property real rowCount: conveyorSettings.rowCount
        property variant source: viewportTexture
        fragmentShader: "
            varying lowp vec2 qt_TexCoord0;
            uniform sampler2D source;
            uniform lowp float qt_Opacity;
            uniform lowp float rowCount;
            void main() {
                lowp vec2 tc;
                lowp float row = floor(qt_TexCoord0.t * rowCount);
                tc.s = qt_TexCoord0.s / rowCount + row / rowCount;
                tc.t = mod(qt_TexCoord0.t, 1.0 / rowCount) * rowCount;
                lowp vec4 tex = texture2D(source, tc);
                gl_FragColor = vec4(tex.rgb, 1.0);
            }
        "
    }
}
