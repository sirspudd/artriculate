import QtQuick 2.5
import QtQuick.Window 2.2
import Qt.labs.settings 1.0

import "basic"

Window {
    id: appWindow

    width: 1024
    height: 768

    property int itemCount

    function reset() {
        itemCount = 0
    }

    QtObject {
        id: globalVars
        property int adjustedInterval: 1000*(generalSettings.interval > 60 ? 60*(generalSettings.interval-60) : generalSettings.interval)*(Math.random()+1)
    }

    Settings {
        id: generalSettings
        property int columnCount: 5
        property int interval: 5
        property bool viewItemCount: false
        property string effect: ""
        property bool smoothArt: false
        property bool randomlyMirrorArt: true
        onColumnCountChanged: reset()
    }

    Rectangle {
        focus: true
        color: "black"
        anchors.fill: parent
        Keys.forwardTo: [punk, toplevelhandler]

        Basic {
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
        function checkModel() {
            visible = (imageModel.rowCount() === 0)
        }

        z: 1
        visible: imageModel.rowCount() === 0
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

    Rectangle {
        z: 1
        opacity: 0.5
        visible: generalSettings.viewItemCount
        color: "black"

        anchors { right: parent.right; top: parent.top }
        width: itemCountLabel.width
        height: itemCountLabel.height

        Text {
            id: itemCountLabel
            font.pixelSize: 100
            text: itemCount
            color: "white"
        }
    }

    Component.onCompleted: showFullScreen()
}
