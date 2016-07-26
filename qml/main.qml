import QtQuick 2.5
import QtQuick.Window 2.2
import Qt.labs.settings 1.0

Window {
    id: appWindow
    //visibility: Window.FullScreen
    visible: true

    width: 1024
    height: 768

    Settings {
        id: settings
        property int itemTravel: 1
        property int columnCount: 30
        property int interval: 2
        property bool fitByHeight: false
        property double pace: 1.0
        property bool viewItemCount: false
        property bool globalWorld: false
    }

    Rectangle {
        focus: true
        color: "black"
        anchors.fill: parent
        Keys.forwardTo: [punk, toplevelhandler]
        Gravity {
            // TODO: generalize all this
            id: punk
        }
    }

    Rectangle {
        id: toplevelhandler
        focus: true
        Keys.onLeftPressed: settings.columnCount = Math.max(settings.columnCount-1,1)
        Keys.onRightPressed: settings.columnCount++
    }

    Rectangle {
        visible: imageModel.rowCount() === 0
        color: "red"
        width: childrenRect.width
        height: childrenRect.height

        anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
        Text {
            font.pointSize: 40
            text: "No images found/provided"
        }
    }

    Component.onCompleted: showFullScreen()
}
