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

    QtObject {
        id: d

        property int footStartingX: -50 - foot.width
        property int mountingDesperation: 1

        readonly property int piMaxTextureSize: 2048
        readonly property int nvidiaMaxTextureSize: 8192
        readonly property int nvidiaMaxTextureSizeTheoretical: 16384

        property int feedGapFudgeFactor: 100
    }

    ImageBoxBody {
        id: foot

        categories: Box.Category1
        collidesWith: Box.Category2

        world: theWorld
        density: 200000
        bodyType: Body.Dynamic
        x: d.footStartingX
        anchors.verticalCenter: viewport.verticalCenter
        fixedRotation: true
        z: 10
        source: "qrc:/Monty_python_foot.png"
        height: viewport.height
        width: viewport.height/foot.implicitHeight*foot.implicitWidth
        sourceSize.height: height
        sourceSize.width: width
        Behavior on x { SmoothedAnimation{ duration: conveyorSettings.footAnimationTime } }
        Component.onCompleted: {
            foot.body.gravityScale = 0
        }
        onBeginContact: {
            var body = pictureArray[pictureArray.length-1].body
            var impulseStrength = body.getMass()*Math.sqrt(conveyorSettings.rowCount)*3*d.mountingDesperation*Math.sqrt((pictureArray.length+1)/conveyorSettings.rowCount)
            body.applyLinearImpulse(Qt.point(impulseStrength,0), Qt.point(0,0));
            withdrawlBoot()
        }
    }

    function bootImage() {
        d.mountingDesperation += 1
        foot.active = true;
        foot.x = pictureArray[pictureArray.length-1].x*2
    }

    function withdrawlBoot() {
        foot.active = false;
        foot.x = d.footStartingX
    }

    function spawnImage() {
        if (foot.x != d.footStartingX)
            return

        if (!nextImage) {
            nextImage = imageDelegate.createObject(viewport, { y: -10000 });
        }

        if (pictureArray.length > 0 && pictureArray[pictureArray.length-1].x < nextImage.width) {
            var body = pictureArray[pictureArray.length-1].body
            if ((body.linearVelocity.y < 0.001) && (body.linearVelocity.x < 1)) {
                bootImage()
            }
        } else {
            nextImage.murder.connect(removeImage)
            nextImage.y = -nextImage.height
            nextImage.world = theWorld

            pictureArray.push(nextImage)
            nextImage = null
            d.mountingDesperation = 1
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

        property int rowCount: 4
        property int footAnimationTime: 500
        property bool constrainToPi: false

        property real friction: 0.01
    }

    Component {
        id: imageDelegate
        ArtBoxBody {
            signal murder(var item)

            categories: Box.Category2
            collidesWith: Box.Category1 | Box.Category2 | Box.Category3

            density: 1
            height: root.height/conveyorSettings.rowCount
            width: height/imageModel.data(modelIndex, PictureModel.SizeRole).height*imageModel.data(modelIndex, PictureModel.SizeRole).width
            bodyType: Body.Dynamic
            fixedRotation: true

            onXChanged: {
                if (x + width > floor.width) {
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

            categories: Box.Category3
            collidesWith: Box.Category2

            world: theWorld
            height: 0
            width: parent.width - root.width/4
            anchors {
                top: parent.bottom
            }
            friction: conveyorSettings.friction
        }
    }

    Timer {
        id: feedTimer
        repeat: true
        running: true
        interval: 200
        onTriggered: {
            spawnImage()
        }
    }

    ShaderEffectSource {
        id: viewportTexture

        sourceItem: viewport
        width: viewport.width
        height: viewport.height
        hideSource: true
        live: true
        textureSize: conveyorSettings.constrainToPi ? Qt.size(d.piMaxTextureSize,d.piMaxTextureSize/root.width*root.height) : undefined
    }

    ShaderEffect {
        anchors.fill: parent
        property real rowCount: conveyorSettings.rowCount
        property variant source: viewportTexture
        blending: false
        cullMode: ShaderEffect.BackFaceCulling
        fragmentShader: "
            varying highp vec2 qt_TexCoord0;
            uniform sampler2D source;
            uniform lowp float qt_Opacity;
            uniform lowp float rowCount;
            void main() {
                highp vec2 tc;
                lowp float row = floor(qt_TexCoord0.t * rowCount);
                tc.s = qt_TexCoord0.s / rowCount + row / rowCount;
                tc.t = mod(qt_TexCoord0.t, 1.0 / rowCount) * rowCount;
                lowp vec4 tex = texture2D(source, tc);
                gl_FragColor = vec4(tex.rgb, 1.0);
            }
        "
    }
}
