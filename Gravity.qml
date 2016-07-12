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

    World {
        // Global world at odds with relative positions!
        id: commonWorld
        timeStep: settings.pace/60.0
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

                timeStep: settings.pace/60.0
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
                    pictureArray.push(pictureDelegate.createObject(column, { y: -2000 }))
                    if (pictureArray.length > settings.columnCount) {
                        pictureArray.shift().detonate()
                    }
                }
            }

            Connections {
                target: root
                onTogglePause: feedTimer.running = !feedTimer.running
                onNext: feedTimer.triggered()
                onToggleChaos: fixedRotation = !fixedRotation
            }

            Timer {
                id: initialPopulation

                property int runCount: 0
                interval: 500
                running: runCount < settings.columnCount
                repeat: true
                onTriggered: {
                    runCount = runCount + 1;
                    feedTimer.triggered()
                }
            }
        }
    }

    Rectangle {
        id: scene
        focus: true
        color: "black"
        anchors.fill: parent

        RectangleBoxBody {
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

        Keys.onLeftPressed: settings.columnCount = Math.max(settings.columnCount-1,1)
        Keys.onRightPressed: settings.columnCount++
        Keys.onUpPressed: root.togglePause()
        Keys.onDownPressed: root.toggleChaos() //root.next()

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
                PropertyAction { target: rect; property: "y"; value: scene.height }
                ParallelAnimation {
                    NumberAnimation { target: rect; property: "x"; to: 2560; duration: 1000 }
                    NumberAnimation { target: rect; property: "y"; to: 0; duration: 1000 }
                }
            }
        }
    }
}
