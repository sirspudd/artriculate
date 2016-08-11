import QtQuick 2.5
import QtQuick.Window 2.2
import Qt.labs.settings 1.0

Window {
    id: appWindow

    width: 1024
    height: 768

    QtObject {
        id: d
        property int primedColumns: 0
    }

    QtObject {
        id: globalUtil
        property int itemCount
        property int currentColumn: 0
        property bool primed: d.primedColumns === columnCount

        property bool commonFeedRoundRobin: globalSettings.commonFeedRoundRobin
        property int columnCount: globalSettings.columnCount
        property int adjustedInterval: 1000*(globalSettings.interval > 60 ? 60*(globalSettings.interval-60) : Math.max(globalSettings.interval, 1))

        function registerColumnPrimed() {
            d.primedColumns++
        }

        function reset() {
            itemCount = currentColumn = d.primedColumns = 0
            loader.item.reset()
        }

        function columnSelection() {
            if (commonFeedRoundRobin) {
                var ret = currentColumn
                currentColumn = (currentColumn + 1) % columnCount
                return ret
            } else {
                return Math.floor(Math.random()*columnCount)
            }
        }
    }

    Settings {
        id: globalSettings
        property int columnCount: 5
        property int interval: 5
        property bool viewItemCount: false
        property string effect: ""
        property string view: "Physics"
        property bool smoothArt: false
        property bool randomlyMirrorArt: true

        property bool commonFeed: true
        property bool commonFeedRoundRobin: true

        onColumnCountChanged: globalUtil.reset()
        Component.onCompleted: loader.source = globalSettings.view.toLowerCase() + "/" + globalSettings.view + ".qml"
    }

    Rectangle {
        focus: true
        color: "black"
        anchors.fill: parent
        Keys.forwardTo: [loader.item, toplevelhandler]

        Loader {
            id: loader
            anchors.fill: parent
            source: "basic/Basic.qml"
        }
    }

    Rectangle {
        id: toplevelhandler
        focus: true
        Keys.onLeftPressed: globalSettings.columnCount = Math.max(globalSettings.columnCount-1,1)
        Keys.onRightPressed: globalSettings.columnCount++
    }

    Rectangle {
        z: 1
        visible: imageModel.rowCount > 0
        color: "red"

        width: childrenRect.width
        height: childrenRect.height
        anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }

        Text {
            font.pointSize: 40
            text: "No images found/provided"
        }
    }

    Rectangle {
        z: 1
        opacity: 0.5
        visible: globalSettings.viewItemCount
        color: "black"

        anchors { right: parent.right; top: parent.top }
        width: itemCountLabel.width
        height: itemCountLabel.height

        Text {
            id: itemCountLabel
            font.pixelSize: 100
            text: globalUtil.itemCount
            color: "white"
        }
    }

    Component.onCompleted: showFullScreen()
}
