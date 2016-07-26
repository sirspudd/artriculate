import QtQuick 2.5
import Box2D 2.0

Item {
    id: root

    signal togglePause
    signal toggleChaos
    signal next

    property var pictureDelegate: Qt.createComponent(settings.fitByHeight ? "VerticalArtDelegate.qml" : "HorizontalArtDelegate.qml")

    anchors.fill: parent

    QtObject {
        id: d
        property double pace: settings.pace/60.0
        property int itemCount: 0
        property int primedColumns: 0
        property int columnCount: settings.columnCount
        property bool running: primedColumns >= columnCount

        function reset() {
            itemCount = 0
            primedColumns = 0
        }

        onColumnCountChanged: reset()
    }

    World {
        id: bullshitWorld
        timeStep: d.pace
        running: d.running
    }

    World {
        // Global world at odds with relative positions!
        id: commonWorld
        timeStep: d.pace
        running: d.running
    }

    Component {
        id: columnComponent

        Item {
            id: column

            property int columnHeight: 0
            property bool full: false

            onColumnHeightChanged: {
                if (!column.full && (columnHeight > root.height)) {
                    d.primedColumns += 1
                    column.full = true
                }
            }

            function addImage() {
                if (columnHeight < (1.1+1/d.columnCount)*root.height) {
                    var item = pictureDelegate.createObject(column)
                    columnHeight += item.height
                    item.y = (floor.y - 1) - columnHeight
                    d.itemCount++
                    pictureArray.push(item)
                }
            }

            x: width * index
            width: parent.width/d.columnCount

            anchors { top: parent.top; bottom: parent.bottom }

            property var pictureArray: []
            property var physicsWorld: settings.globalWorld ? commonWorld : columnWorld
            property bool fixedRotation: true

            World {
                id: columnWorld

                timeStep: d.pace
                running: d.running
            }

            RectangleBoxBody {
                world: physicsWorld
                height: 1
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.bottom
                }
                friction: 1
                density: 1
            }

            Timer {
                id: pumpTimer
                interval: Math.random()*500 + 500
                repeat: true
                running: true
                onTriggered: {
                    column.addImage()
                }
            }

            Timer {
                id: deathTimer
                running: d.running
                repeat: true
                interval: 1000*(settings.interval > 60 ? 60*(settings.interval-60) : settings.interval)*(Math.random()+1)
                onTriggered: {
                    if (pictureArray.length > 0) {
                        var image = pictureArray.shift()
                        image.world = bullshitWorld
                        image.freefall = true
                        d.itemCount--
                        columnHeight -= image.height
                    }
                }
            }

            Connections {
                target: root
                onTogglePause: deathTimer.running = !deathTimer.running
                onNext: deathTimer.triggered()
                onToggleChaos: fixedRotation = !fixedRotation
            }

            Timer {
                id: settleTimer
                running: false
                interval: 200
                onTriggered: deathTimer.triggered()
            }
        }
    }

    // floor
    RectangleBoxBody {
        id: floor
        world: commonWorld
        height: 1
        anchors {
            left: parent.left
            right: parent.right
            top: parent.bottom
        }
        friction: 1
        density: 1
    }

    Repeater {
        model: d.columnCount
        delegate: columnComponent
    }

    // TODO: The boot (Monty Python foot) of death to be applied to the stacks
    RectangleBoxBody {
        id: rect
        enabled: false
        visible: false
        friction: 1.0
        density: 1000
        color: "red"
        width: 50; height: 50
        bullet: true
        SequentialAnimation {
            id: murderAnimation
            //loops: Animation.Infinite
            //running: true
            ScriptAction { script: { root.togglePause() } }
            ScriptAction { script: { rect.world = worldArray.pop() } }
            PropertyAction { target: rect; property: "x"; value: -rect.width }
            PropertyAction { target: rect; property: "y"; value: root.height }
            ParallelAnimation {
                NumberAnimation { target: rect; property: "x"; to: 2560; duration: 1000 }
                NumberAnimation { target: rect; property: "y"; to: 0; duration: 1000 }
            }
        }
    }

    Rectangle {
        visible: settings.viewItemCount
        z: 1
        color: "black"
        anchors { right: parent.right; top: parent.top }
        width: itemCountLabel.width
        height: itemCountLabel.height
        Text {
            id: itemCountLabel
            font.pixelSize: 100
            text: d.itemCount
            color: "white"
        }
    }

    Keys.onUpPressed: root.togglePause()
    Keys.onDownPressed: root.toggleChaos() //root.next()
}
