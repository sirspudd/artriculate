import QtQuick 2.5
import Box2D 2.0
import Qt.labs.settings 1.0

// Forgive me
import "../.."

View {
    id: root

    signal togglePause
    signal toggleChaos
    signal next

    property var pictureDelegate: Component {
        WellDelegate {}
    }

    Settings {
        id: wellSettings
        category: "Well"

        property int feedRate: 100
        // 0 is abutting
        property bool graduatedColumns: true
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
        property real pace: wellSettings.pace/60.0
        property bool paused: false
    }

    World {
        id: world
        timeStep: d.pace
        running: wellSettings.globalWorld && globalUtil.primed
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
            property int cappedXOffset: index ? parent.width*graduationFactor : 0
            property int xOffset: wellSettings.graduatedColumns ? cappedXOffset : width * index
            property var pictureArray: []
            property real graduationFactor: {
                var cappedPositionalWeight = index ? index : 1
                var graduationFactor=1.0/(Math.pow(2,(globalSettings.columnCount - cappedPositionalWeight)))
                return graduationFactor
            }

            function considerImage() {
                if (stackHeight < (1.3 + 1/globalSettings.columnCount)*root.height) {
                    addImage()
                }
            }

            function addImage() {
                var image = pictureDelegate.createObject(column, { x: -1000, y: -1000 })

                image.beyondThePale.connect(removeImage)
                image.world = wellSettings.globalWorld ? world : isolatedWorld
                image.x = xOffset
                stackHeight += image.height
                image.y = floor.y - stackHeight - wellSettings.verticalOffset

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

            onStackHeightChanged: {
                if (!column.full && (stackHeight > root.height)) {
                    globalUtil.registerColumnPrimed()
                    column.full = true
                }
            }

            width: wellSettings.graduatedColumns ? parent.width*graduationFactor : parent.width/globalSettings.columnCount
            anchors { top: parent.top; bottom: parent.bottom }

            World {
                id: isolatedWorld
                timeStep: d.pace
                running: !wellSettings.globalWorld && globalUtil.primed
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
                interval: Math.abs(wellSettings.feedRate)
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
                function onTogglePause() { d.paused = !d.paused }
                function onNext() { deathTimer.triggered() }
                function onToggleChaos() { wellSettings.fixedRotation = !wellSettings.fixedRotation }
            }

            Component.onCompleted: {
                columnArray.push(this)
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
