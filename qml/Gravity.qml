import QtQuick 2.5
import Box2D 2.0
import "effects"

Item {
    id: root

    signal togglePause
    signal toggleChaos
    signal next

    property var pictureDelegate: Qt.createComponent("HorizontalArtDelegate.qml")
    property var effectDelegate: Qt.createComponent("VisualEffect.qml")

    anchors.fill: parent

    QtObject {
        id: d
        property real pace: settings.pace/60.0
        property int itemCount: 0
        property int itemTravel: settings.itemTravel
        property int primedColumns: 0
        property int columnCount: settings.columnCount
        property bool running: primedColumns >= columnCount
        property bool globalWorld: settings.globalWorld
        property string effect: settings.effect

        function reset() {
            itemCount = 0
            primedColumns = 0
        }

        onColumnCountChanged: reset()
    }

    World {
        id: world
        timeStep: d.pace
        running: d.globalWorld && d.running
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

            onStackHeightChanged: {
                if (!column.full && (stackHeight > root.height)) {
                    d.primedColumns += 1
                    column.full = true
                }
            }

            function considerImage() {
                if (stackHeight < (1.3 + 1/d.columnCount)*root.height) {
                    addImage()
                }
            }

            function addImage() {
                var image = pictureDelegate.createObject(column, { x: -1000, y: -1000 })

                if (d.effect !== "" && Effects.validate(d.effect)) {
                    image.effect = effectDelegate.createObject(column, { target: image, effect: d.effect })
                }

                image.beyondThePale.connect(removeImage)
                image.world = d.globalWorld ? world : isolatedWorld
                image.x = xOffset
                stackHeight += (image.height + d.itemTravel)
                image.y = floor.y - stackHeight

                pictureArray.push(image)
                d.itemCount++
            }

            function removeImage(image) {
                if (image.effect) {
                    image.effect.destroy()
                }
                stackHeight -= (image.height + d.itemTravel)
                image.destroy()
                d.itemCount--
            }

            function shiftImageToLimbo() {
                if (pictureArray.length > 0) {
                    var image = pictureArray.shift()
                    image.world = image.world.limbo
                    addImage()
                }
            }

            width: parent.width/d.columnCount

            anchors { top: parent.top; bottom: parent.bottom }

            property var pictureArray: []
            property bool fixedRotation: true

            World {
                id: isolatedWorld
                timeStep: d.pace
                running: !d.globalWorld && d.running
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
                interval: Math.random()*500 + 500
                repeat: true
                running: true
                onTriggered: considerImage()
            }

            Timer {
                id: deathTimer
                running: d.running
                repeat: true
                interval: 1000*(settings.interval > 60 ? 60*(settings.interval-60) : settings.interval)*(Math.random()+1)
                onTriggered: shiftImageToLimbo()
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

    Component.onCompleted: {
        pictureDelegate.status !== Component.Ready && console.log('Component failed with:' + pictureDelegate.errorString())
        effectDelegate.status !== Component.Ready && console.log('Component failed with:' + effectDelegate.errorString())
    }
}
