import QtQuick 2.5
import Box2D 2.0
import Qt.labs.settings 1.0

import ".."

View {
    id: root

    signal togglePause
    signal toggleChaos
    signal next

    property var columnArray: []
    property var pictureDelegate: Component {
        CascadeDelegate {}
    }

    anchors.fill: parent

    QtObject {
        id: d
        property int columnCount: 6
        property real pace: cascadeSettings.pace/60.0
        property bool paused: false
    }

    Repeater {
        model: d.columnCount
        delegate: columnComponent
    }

    Settings {
        id: cascadeSettings
        category: "Cascade"

        property int feedRate: 1000
        // 0 is abutting
        property int verticalOffset: 500
        property real pace: 3
        property real density: 1.0
        property real friction: 1.0
        // Very computationally heavy: 40% vs 20% for 0.1 vs 0
        property real restitution: 0
    }

    Component {
        id: columnComponent

        Item {
            id: column

            property bool shifty: false
            property int stackHeight: 0
            property int xOffset: width * index
            property var pictureArray: []

            function addExistingImage(image) {
                // make sure there is no spacial conflict in limbo, or shit goes tits up
                image.x = image.y = index*-1000
                image.linearVelocity.x = image.linearVelocity.y = 0.0
                image.beyondThePale.connect(removeImage)
                image.x = xOffset
                stackHeight += image.height
                image.y = -image.height - pictureArray.length*100
                image.world = isolatedWorld

                pictureArray.push(image)
            }

            function addImage() {
                var image = pictureDelegate.createObject(column, { x: -1000, y: -1000 })
                addExistingImage(image)

                globalUtil.itemCount++
            }

            function removeImage(image) {
                image.beyondThePale.disconnect(removeImage)
                stackHeight -= image.height
                //console.log('Image slipped through the cracks')
                if (index === d.columnCount-1) {
                    console.log('Image deleted')
                    image.destroy()
                    globalUtil.itemCount--
                } else {
                    columnArray[index+1].addExistingImage(image)
                }
            }

            function shift() {
                if (pictureArray.length > 0) {
                    var image = pictureArray.shift()
                    image.world = image.world.limbo
                }
            }

            onStackHeightChanged: {
                if (stackHeight > (1.3 + 1/d.columnCount)*root.height) {
                    shifty = true
                }
            }

            width: parent.width/globalSettings.columnCount
            anchors { top: parent.top; bottom: parent.bottom }

            World {
                id: isolatedWorld
                timeStep: d.pace
                running: true
                property var limbo: World {
                    timeStep: isolatedWorld.timeStep
                    running: isolatedWorld.running
                }
            }

            RectangleBoxBody {
                id: floor
                world: isolatedWorld
                height: 0
                width: parent.width
                x: xOffset
                anchors {
                    top: parent.bottom
                }
                friction: 1
            }

            Timer {
                id: pumpTimer
                interval: 1000
                repeat: true
                running: (index === 0) && !shifty
                onTriggered: addImage()
            }

            Timer {
                id: deathTimer
                running: true
                repeat: true
                interval: 5000
                onTriggered: {
                    if (shifty) {
                        shift()
                        shifty = false
                    }
                }
            }

            Connections {
                target: root
                onTogglePause: d.paused = !d.paused
                onNext: deathTimer.triggered()
            }

            Component.onCompleted: {
                columnArray.push(this)
            }
        }
    }

    Keys.onUpPressed: root.togglePause()
    Keys.onDownPressed: root.toggleChaos() //root.next()

    Component.onCompleted: {
        globalVars.loadFullImage = true
        pictureDelegate.status !== Component.Ready && console.log('Component failed with:' + pictureDelegate.errorString())
    }
}
