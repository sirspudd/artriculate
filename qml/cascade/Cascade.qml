import QtQuick 2.5
import Box2D 2.0
import Qt.labs.settings 1.0

import ".."

Item {
    id: root

    signal togglePause
    signal next

    property var columnArray: []
    property var pictureDelegate: Component {
        CascadeDelegate {}
    }

    anchors.fill: parent

    Settings {
        id: cascadeSettings
        category: "Cascade"
        property int columnCount: 5
        property int feedRate: 1000
    }

    QtObject {
        id: d
        property real goldenRatio: 1.61803398875
        property real pace: 1.0/20.0
        property bool paused: false
        function goldenBeast(col) {
            return (1 - d.goldenRatio)/(1 - Math.pow(d.goldenRatio, col))
        }

        property real columnWidth: {
            var foo = root.width*goldenBeast(cascadeSettings.columnCount)
            console.log('Column width is:', foo)
            return foo
        }
    }

    Repeater {
        model: cascadeSettings.columnCount
        delegate: columnComponent
    }

    Component {
        id: columnComponent

        Item {
            id: column

            property int stackHeight: 0
            property int xOffset: d.columnWidth/d.goldenBeast(index)
            property var pictureArray: []
            property bool full: stackHeight > (1.3 + 1/cascadeSettings.columnCount)*root.height

            function addExistingImage(image) {
                // make sure there is no spacial conflict in limbo, or shit goes tits up
                image.width = width
                image.x = image.y = index*-1000
                image.linearVelocity.x = image.linearVelocity.y = 0.0
                image.beyondThePale.connect(removeImage)

                stackHeight += image.height
                image.x = xOffset
                image.y = - stackHeight
                image.world = isolatedWorld

                pictureArray.push(image)
            }

            function addImage() {
                var image = pictureDelegate.createObject(column)
                addExistingImage(image)
                globalUtil.itemCount++
            }

            function removeImage(image) {
                image.beyondThePale.disconnect(removeImage)
                if (index === cascadeSettings.columnCount-1) {
                    image.destroy()
                    globalUtil.itemCount--
                } else {
                    columnArray[index+1].addExistingImage(image)
                }
            }

            function shift() {
                var image = pictureArray.shift()
                image.world = image.world.limbo
                stackHeight -= image.height
            }

            width: d.columnWidth*Math.pow(d.goldenRatio, index)
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
                interval: full ? cascadeSettings.feedRate : 10
                repeat: true
                running: index === 0
                onTriggered: addImage()
            }

            Timer {
                id: deathTimer
                running: full
                repeat: true
                interval: cascadeSettings.feedRate
                onTriggered: {
                    shift()
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
