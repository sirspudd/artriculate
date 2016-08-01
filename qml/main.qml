import QtQuick 2.5
import QtQuick.Window 2.2
import Qt.labs.settings 1.0

import "physics"

Window {
    id: appWindow

    width: 1024
    height: 768

    Settings {
        id: generalSettings
        property int columnCount: 5
        property int interval: 5
        property bool viewItemCount: false
        property string effect: ""
    }

    Rectangle {
        focus: true
        color: "black"
        anchors.fill: parent
        Keys.forwardTo: [punk, toplevelhandler]

        Physics {
            // TODO: generalize all this
            id: punk
        }
    }

    Rectangle {
        id: toplevelhandler
        focus: true
        Keys.onLeftPressed: generalSettings.columnCount = Math.max(generalSettings.columnCount-1,1)
        Keys.onRightPressed: generalSettings.columnCount++
    }

    Rectangle {
        visible: imageModel.rowCount() === 0

        function checkModel() {
            visible = (imageModel.rowCount() === 0)
        }

        color: "red"
        width: childrenRect.width
        height: childrenRect.height
        anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }

        Text {
            font.pointSize: 40
            text: "No images found/provided"
        }

        Component.onCompleted: modelRelay.countChanged.connect(checkModel);
    }

    Component.onCompleted: showFullScreen()
}
