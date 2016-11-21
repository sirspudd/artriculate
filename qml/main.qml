import QtQuick 2.5
import QtQuick.Window 2.2
import Qt.labs.settings 1.0
import PictureModel 1.0

Window {
    id: appWindow

    width: 1024
    height: 768

    onWidthChanged: {
        loader.source = ""
        loader.source = globalSettings.view.toLowerCase() + "/" + globalSettings.view + ".qml"
    }

    PictureModel {
        id: imageModel
    }

    QtObject {
        id: d
        property int primedColumns: 0
        property string timeString

        function timeChanged() {
            var date = new Date;
            timeString = ("00" + date.getHours()).slice(-2) + ':' + ("00" + date.getMinutes()).slice(-2);
        }

        property variant timeTimer: Timer {
            interval: 1000; running: true; repeat: true;
            onTriggered: d.timeChanged()
        }
    }

    QtObject {
        id: globalUtil
        property int itemCount
        property int currentColumn: 0
        property bool primed: d.primedColumns === globalSettings.columnCount

        property int adjustedInterval: 1000*(globalSettings.interval > 60 ? 60*(globalSettings.interval-60) : Math.max(globalSettings.interval, 1))

        function registerColumnPrimed() {
            d.primedColumns++
        }

        function reset() {
            itemCount = currentColumn = d.primedColumns = 0
            loader.item.reset()
        }

        function columnSelection() {
            if (globalSettings.commonFeedRoundRobin) {
                var ret = currentColumn
                currentColumn = (currentColumn + 1) % globalSettings.columnCount
                return ret
            } else {
                return Math.floor(Math.random()*globalSettings.columnCount)
            }
        }
    }

    Settings {
        id: globalSettings
        property int columnCount: 5
        property int interval: 5
        property bool showViewItemCount: false
        property bool showScreenResolution: false
        property string effect: ""
        property string view: "Basic"
        property bool smoothArt: false
        property bool randomlyMirrorArt: true
        property bool fullscreen: true


        property bool clockWidget: false
        property real clockIntensity: 0.6

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
        }

        Rectangle {
            id: clock
            width: childrenRect.width
            opacity: 0.7
            color: "black"
            visible: height > 0
            height: globalSettings.clockWidget ? appWindow.height/15 : 0
            anchors { top: parent.top; horizontalCenter: parent.horizontalCenter }
            Text {
                anchors.centerIn: parent
                color: "white"//Qt.rgba(globalSettings.clockIntensity, globalSettings.clockIntensity, globalSettings.clockIntensity, 1.0)
                font.bold: true
                font.pixelSize: parent.height
                text: d.timeString
            }
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
        visible: globalSettings.showViewItemCount
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

    Rectangle {
        z: 1
        opacity: 0.5
        visible: globalSettings.showScreenResolution
        color: "black"

        anchors { right: parent.right; top: parent.top }
        width: resolutionLabel.width
        height: resolutionLabel.height

        Text {
            id: resolutionLabel
            font.pixelSize: 100
            text: screenSize.width + "x" + screenSize.height
            color: "white"
        }
    }

    Component.onCompleted: {
        globalSettings.fullscreen ? showFullScreen() : show()
    }
}
