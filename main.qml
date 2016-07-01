import QtQuick 2.5
import QtQuick.Window 2.2
import Qt.labs.settings 1.0
import Box2D 2.0

Window {
    id: root
    visibility: Window.FullScreen

    width: 1024
    height: 768

    Settings {
        id: settings
        property int columnCount: 4
        property int interval: 30
    }

    signal pause
    signal next

    Component {
        id: pictureComponent
        ImageBoxBody {
            id: picture
            function detonate() { destroyAnimation.start() }
            //I thought this accepted forcing either width/height
            //fillMode: Image.PreserveAspectFit
            height: implicitHeight/implicitWidth*width
            width: parent.width
            density: 0.01
            friction: 1.0
            fixedRotation: true
            world: parent.physicsWorld
            bodyType: Body.Dynamic
            source: "file://" + imageModel.randomPicture()
            //restitution: 0.0
            onXChanged: x = 0
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
            width: parent.width/settings.columnCount

            anchors { top: parent.top; bottom: parent.bottom }

            property var pictureArray: []
            property var physicsWorld: World {
                timeStep: 6.0/60.0
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
                    pictureArray.push(pictureComponent.createObject(column, { y: -2000 }))
                    if (pictureArray.length > settings.columnCount) {
                        pictureArray.shift().detonate()
                    }
                }
            }

            Connections {
                target: root
                onPause: feedTimer.running = !feedTimer.running
                onNext: feedTimer.triggered()
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
        focus: true
        color: "black"
        anchors.fill: parent
        Repeater {
            model: settings.columnCount
            delegate: columnComponent
        }
        Keys.onLeftPressed: settings.columnCount = Math.max(settings.columnCount-1,1)
        Keys.onRightPressed: settings.columnCount++
        Keys.onUpPressed: root.pause()
        Keys.onDownPressed: root.next()
    }

}
