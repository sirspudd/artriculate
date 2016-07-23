import QtQuick 2.5
import Box2D 2.0

Item {
    id: root

    signal togglePause
    signal toggleChaos
    signal next

    property bool globalWorld: settings.fitByHeight
    property var worldArray: []
    property var pictureDelegate: Qt.createComponent(settings.fitByHeight ? "VerticalArtDelegate.qml" : "HorizontalArtDelegate.qml")

    anchors.fill: parent

    QtObject {
        id: d
        property double pace: settings.pace/60.0
        property int itemCount: 0
    }

    World {
        id: bullshitWorld
        timeStep: d.pace
    }

    World {
        // Global world at odds with relative positions!
        id: commonWorld
        timeStep: d.pace
    }

    Component {
        id: columnComponent

        Item {
            id: column
            x: xOffset - effectiveXOffset
            width: parent.width/settings.columnCount

            anchors { top: parent.top; bottom: parent.bottom }

            property var pictureArray: []
            property var physicsWorld: settings.globalWorld ? commonWorld : columnWorld
            property bool fixedRotation: true
            property int xOffset: width * index
            property int effectiveXOffset: settings.globalWorld ? xOffset : 0

            World {
                id: columnWorld

                timeStep: d.pace
                Component.onCompleted: worldArray.push(columnWorld)
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
                id: feedTimer
                running: true
                repeat: true
                interval: 1000*(settings.interval > 60 ? 60*(settings.interval-60) : settings.interval)*(Math.random()+1)
                onTriggered: {
                    if (pictureArray.length > 0) {
                        pictureArray.shift().world = bullshitWorld
                    }

                    var colHeight = pictureArray.reduce(function (height, image) { return height + image.height; }, 0)

                    do {
                        var item = pictureDelegate.createObject(column)
                        item.leftViewport.connect(function() { d.itemCount--; })
                        item.y = -colHeight - item.height
                        d.itemCount++
                        pictureArray.push(item)
                        colHeight += item.height
                    } while (colHeight < 1.5*root.height)
                }
            }

            Connections {
                target: root
                onTogglePause: feedTimer.running = !feedTimer.running
                onNext: feedTimer.triggered()
                onToggleChaos: fixedRotation = !fixedRotation
            }

            Timer {
                id: settleTimer
                running: false
                interval: 200
                onTriggered: feedTimer.triggered()
            }

            Component.onCompleted: settleTimer.start()
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
        model: settings.columnCount
        delegate: columnComponent
    }

    Connections {
        target: settings
        onColumnCountChanged: d.itemCount = 0
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
