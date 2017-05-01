import QtQuick 2.0

// pretty much entirely stolen from:
// https://github.com/capisce/motionblur/blob/master/main.qml

Rectangle {
    color: "black"

    property real t
    property int frame: 0

    height: fpsText.height
    width: fpsText.width

    Text {
        id: fpsText

        font.pixelSize: 100
        color: "white"
        text: "FPS:" + fpsTimer.fps
    }

    Timer {
        id: fpsTimer
        property real fps: 0
        repeat: true
        interval: 1000
        running: true
        onTriggered: {
            fps = frame
            frame = 0
        }
    }

    NumberAnimation on t {
        id: tAnim
        from: 0
        to: 100
        loops: Animation.Infinite
    }

    onTChanged: {
        update() // force continuous animation
        ++frame
    }
}
