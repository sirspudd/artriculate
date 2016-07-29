import QtQuick 2.5
import QtQuick.Window 2.2
import Qt.labs.settings 1.0

Window {
    id: appWindow

    width: 1024
    height: 768

    Settings {
        id: settings
        property int itemTravel: 0
        property int columnCount: 5
        property int interval: 5
        property real pace: 1
        property bool viewItemCount: false
        property bool globalWorld: false
        // Very computationally heavy: 40% vs 20% for 0.1 vs 0
        property real restitution: 0
        property bool embossEffect: false
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
