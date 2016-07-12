import QtQuick 2.5
import QtQuick.Window 2.2
import Qt.labs.settings 1.0

Window {
    id: appWindow
    visibility: Window.FullScreen

    width: 1024
    height: 768

    Settings {
        id: settings
        property int columnCount: 4
        property int interval: 30
        property bool animateDeath: false
        property bool fitByHeight: true
        property double pace: 6.0
    }

    Gravity {
        anchors.fill: parent
    }
}
