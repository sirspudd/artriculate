import QtQuick 2.5
import Box2D 2.0
import QtCore
import PictureModel 1.0

// Forgive me
import "../.."

Item {
    id: root

    signal togglePause
    signal next

    property var columnArray: []
    property var pictureDelegate: Component {
        CascadeDelegate {}
    }

    function drain() {
        // TODO: implement draining of all visible artwork
    }

    anchors.fill: parent

    Settings {
        id: cascadeSettings
        category: "Cascade"
        property int initialFeedRate: 500
    }

    QtObject {
        id: d
        property int feedrate: populated ? globalUtil.adjustedInterval : cascadeSettings.initialFeedRate
        property bool populated: false
        property bool paused: false
        property real columnRatio: globalSettings.useGoldenRatio ? globalVars.goldenRatio : globalSettings.lessGoldenRatio
        property real pace: 1.0/30.0
        property real columnWidth: root.width*globalUtil.columnWidthRatio(d.columnRatio, globalSettings.columnCount)
    }

    Repeater {
        model: globalSettings.columnCount
        delegate: columnComponent
    }

    Component {
        id: columnComponent

        Item {
            id: column

            property int stackHeight: 0
            property int xOffset: d.columnWidth/globalUtil.columnWidthRatio(d.columnRatio, index)
            property var pictureArray: []
            property var pictureQueue: []
            property bool full: {
                var fullStack = stackHeight > (1.3 + 1/globalSettings.columnCount)*root.height
                !d.populated && fullStack && (index === (globalSettings.columnCount - 1)) && (d.populated = true)
                return fullStack
            }

            function addExistingImage(image) {
                image.width = width
                image.x = image.y = index*-1000
                image.linearVelocity.x = image.linearVelocity.y = 0.0
                image.beyondThePale.connect(removeImage)
                stackHeight += image.height
                image.x = xOffset
                image.y = index == 0 ? root.height - stackHeight : -stackHeight - pictureArray.length*10
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
                if (index === (globalSettings.columnCount - 1)) {
                    image.destroy()
                    globalUtil.itemCount--
                } else {
                    columnArray[index+1].pictureQueue.push(image)
                }
            }

            function shift() {
                var image = pictureArray.shift()
                image.world = image.world.limbo
                stackHeight -= image.height
            }

            width: {
                var colWidth = d.columnWidth*Math.pow(d.columnRatio, index);
                (index === (globalSettings.columnCount - 1)) && (globalVars.imageWidthOverride = colWidth)
                return colWidth
            }
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
                interval: d.feedrate
                repeat: true && !d.paused
                running: true
                onTriggered: {
                    if (index === 0) {
                        addImage()
                    } else {
                        pictureQueue.length && addExistingImage(pictureQueue.shift())
                    }
                }
            }

            Timer {
                id: deathTimer
                running: full
                repeat: true
                interval: d.feedrate
                onTriggered: shift()
            }

            Connections {
                target: root
                function onTogglePause() { d.paused = !d.paused }
                function onNext() { deathTimer.triggered() }
            }

            Component.onCompleted: {
                columnArray.push(this)
            }
        }
    }

    Keys.onUpPressed: d.paused = !d.paused
    Keys.onDownPressed: root.drain()

    Component.onCompleted: {
        pictureDelegate.status !== Component.Ready && console.log('Component failed with:' + pictureDelegate.errorString())
    }
}
