import QtQuick

// pretty much entirely stolen from:
// https://github.com/capisce/motionblur/blob/master/main.qml

// Required for effortless web serving!

Widget {
    property real t
    property int frame: 0

    text: "FPS:" + fpsTimer.fps

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
