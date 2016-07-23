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
        property int columnCount: 4
        property int interval: 30
        property bool fitByHeight: false
        property double pace: 1.0
        property double columnBufferFactor: 1.2
        property bool viewItemCount: false
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

    Component.onCompleted: showFullScreen()
}
