import QtQuick

Item {
    z: 1
    anchors { right: parent.right; bottom: parent.bottom }
    width: appWindow.width/2
    height: appWindow.height/2

    Text {
        z: 1
        color: "white"
        font.pointSize: 60
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top }
        text: "UNLICENCED"
    }

    Image {
        id: mug
        property int revolutions: 1000000
        fillMode: Image.PreserveAspectFit
        height: appWindow.height/2
        anchors { centerIn: parent }
        source: "unlicensed.png"
        RotationAnimator {
               target: mug;
               from: 0;
               to: 360*mug.revolutions
               duration: 2000*mug.revolutions
               running: mug.visible
           }
    }

    Text {
        z: 1
        color: "white"
        font.pointSize: 60
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom }
        text: "COPY"
    }
}
