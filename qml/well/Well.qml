import QtQuick 2.5
import Box2D 2.0
import Qt.labs.settings 1.0

import ".."

View {
    id: root

    signal togglePause
    signal toggleChaos
    signal next

    property var pictureDelegate: Component {
        WellDelegate {}
    }

    Settings {
        id: physicsSettings
        category: "Physics"

        property int feedRate: 100
        // 0 is abutting
        property int verticalOffset: 5
        property real pace: 3
        property real density: 1.0
        property real friction: 1.0
        property bool globalWorld: false
        property bool fixedRotation: true
        // Very computationally heavy: 40% vs 20% for 0.1 vs 0
        property real restitution: 0
    }

    QtObject {
        id: d
        property real pace: physicsSettings.pace/60.0
        property bool paused: false
    }

    World {
        id: world
        timeStep: d.pace
        running: physicsSettings.globalWorld && globalUtil.primed
        property var limbo: World {
            timeStep: world.timeStep
            running: world.running
        }
    }

    Component {
        id: columnComponent

        Item {
            id: column

            property int stackHeight: 0
            property bool full: false
            property int xOffset: width * index
            property var pictureArray: []

            function considerImage() {
                if (stackHeight < (1.3 + 1/globalSettings.columnCount)*root.height) {
                    addImage()
                }
            }

            function addImage() {
                var image = pictureDelegate.createObject(column, { x: -1000, y: -1000 })

                image.beyondThePale.connect(removeImage)
                image.world = physicsSettings.globalWorld ? world : isolatedWorld
                image.x = xOffset
                stackHeight += image.height
                image.y = floor.y - stackHeight - physicsSettings.verticalOffset

                pictureArray.push(image)
                globalUtil.itemCount++
            }

            function removeImage(image) {
                stackHeight -= image.height
                image.destroy()
                globalUtil.itemCount--
            }

            function shift() {
                if (pictureArray.length > 0) {
                    var image = pictureArray.shift()
                    image.world = image.world.limbo
                    addImage()
                }
            }

            Component.onCompleted: {
                columnArray.push(this)
            }

            onStackHeightChanged: {
                if (!column.full && (stackHeight > root.height)) {
                    globalUtil.registerColumnPrimed()
                    column.full = true
                }
            }

            width: parent.width/globalSettings.columnCount
            anchors { top: parent.top; bottom: parent.bottom }

            World {
                id: isolatedWorld
                timeStep: d.pace
                running: !physicsSettings.globalWorld && globalUtil.primed
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
                interval: Math.abs(physicsSettings.feedRate)
                repeat: true
                running: true
                onTriggered: considerImage()
            }

            Timer {
                id: deathTimer
                running: !globalSettings.commonFeed && globalUtil.primed && d.paused
                repeat: true
                interval: globalUtil.adjustedInterval
                onTriggered: shift()
            }

            Connections {
                target: root
                onTogglePause: d.paused = !d.paused
                onNext: deathTimer.triggered()
                onToggleChaos: physicsSettings.fixedRotation = !physicsSettings.fixedRotation
            }
        }
    }

    // floor
    RectangleBoxBody {
        id: globalFloor
        world: world
        height: 0
        anchors {
            left: parent.left
            right: parent.right
            top: parent.bottom
        }
        friction: 1
    }

    DebugDraw {
        id: debugDraw
        enabled: false
        z: 1
        world: world
        anchors.fill: parent
        opacity: 0.75
        visible: enabled
    }

    Keys.onUpPressed: root.togglePause()
    Keys.onDownPressed: root.toggleChaos() //root.next()

    Component.onCompleted: {
        pictureDelegate.status !== Component.Ready && console.log('Component failed with:' + pictureDelegate.errorString())
    }
}