import QtQuick 2.5
import QtQuick.Window 2.2
import Box2D 2.0

Window {
    id: root
    visibility: Window.FullScreen

    width: 1024
    height: 768

    property int columnCount: 4
    property int interval: 5

    Component {
        id: pictureComponent
        ImageBoxBody {
            id: picture
            function detonate() { destroyAnimation.start() }
            fillMode: Image.PreserveAspectFit
            height: implicitHeight/implicitWidth*width
            width: parent.width
            density: 0
            fixedRotation: true
            world: parent.physicsWorld
            bodyType: Body.Dynamic
            source: "file://" + imageModel.randomPicture()
            restitution: 0.0
            SequentialAnimation {
                id: destroyAnimation
                ScriptAction { script: { picture.destroy(); } }
            }
        }
    }

    Component {
        id: columnComponent

        Item {
            id: column
            x: width * index
            width: parent.width/columnCount

            anchors { top: parent.top; bottom: parent.bottom }

            property var pictureArray: []
            property var physicsWorld: World {
                timeStep: 0.1
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
                interval: 1000*(root.interval > 60 ? 60*(root.interval-60) : root.interval)
                onTriggered: {
                    pictureArray.push(pictureComponent.createObject(column, { y: -500 }))
                    if (pictureArray.length > root.columnCount) {
                        pictureArray.shift().detonate()
                    }
                }
            }

            Timer {
                id: initialPopulation

                property int runCount: 0
                interval: 500
                running: runCount < root.columnCount
                repeat: true
                onTriggered: {
                    runCount = runCount + 1;
                    feedTimer.triggered()
                }
            }
        }
    }

    Rectangle {
        color: "black"
        anchors.fill: parent
        Repeater {
            model: columnCount
            delegate: columnComponent
        }
    }
}
