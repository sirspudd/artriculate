import QtQuick 2.8

Effect {
    property real amplitude: 0.04 * 0.05
    property real frequency: 20
    property real time: 0
    NumberAnimation on time { loops: Animation.Infinite; from: 0; to: Math.PI * 2; duration: 600 }
    fragmentShader: Qt.resolvedUrl("shaders/wobble.fsh")
}