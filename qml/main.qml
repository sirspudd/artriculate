import QtQuick 2.5
import QtQuick.Window 2.2
import Qt.labs.settings 1.0
import PictureModel 1.0

Window {
    id: appWindow

    width: 1280
    height: 720

    onWidthChanged: {
        globalUtil.reset()
    }

    function showAtCorrectSize() {
        globalSettings.fullscreen ? showFullScreen() : show()
    }

    PictureModel {
        id: imageModel
    }

    QtObject {
        id: globalVars
        property real goldenRatio
        property real imageWidthOverride
        property bool globalDeathTimer

        function reset() {
            goldenRatio = 1.61803398875
            imageWidthOverride = -1
            globalDeathTimer = false
        }

        Component.onCompleted: reset()
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
            if (d.currentViewFilename) {
                globalVars.reset()
                artViewLoader.source = ""
                artViewLoader.source = d.currentViewFilename
                itemCount = currentColumn = d.primedColumns = 0
            }
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

        function columnWidthRatio(ratio, col) {
            return (1 - ratio)/(1 - Math.pow(ratio, col))
        }
    }

    QtObject {
        id: d
        property int primedColumns: 0
        property string timeString
        property string day
        property string month
        property string currentViewFilename
        property string overrideViewFilename
        property bool displayUnlicensed: false

        function setView(view) {
            d.currentViewFilename = deriveViewPath(overrideViewFilename.length ? overrideViewFilename : view)
        }

        function deriveViewPath(view) {
            return view.toLowerCase() + "/" + view + ".qml"
        }

        function timeChanged() {
            var date = new Date;
            timeString = Qt.formatDateTime(date, "hh:mm")
            day = Qt.formatDateTime(date, "dd")
            month = Qt.formatDateTime(date, "MM")
        }

        property variant timeTimer: Timer {
            interval: 1000; running: true; repeat: true;
            onTriggered: d.timeChanged()
        }

        onCurrentViewFilenameChanged: {
            globalUtil.reset()
        }
    }

    Settings {
        id: globalSettings
        property int columnCount: 6
        property int interval: 5
        property bool showViewItemCount: false
        property bool showScreenResolution: false
        property string effect: ""
        property string view: "Reel"
        property string backdrop: ""
        property bool smoothArt: false
        property bool randomlyMirrorArt: true
        property bool fullscreen: true

        property bool clockWidget: false
        property real clockIntensity: 0.6

        property bool commonFeed: true
        property bool commonFeedRoundRobin: true

        property bool unlicensed: false

        property real artOpacity: 1.0
        property bool fadeInImages: true

        property bool animatedBackground: false

        property bool useGoldenRatio: false
        //property real lessGoldenRatio: 1.25
        property real lessGoldenRatio: 1.35

        onColumnCountChanged: globalUtil.reset()
        onFullscreenChanged: showAtCorrectSize()

        Component.onCompleted: {
            d.setView(view)
        }
    }

    Item {
        id: root
        focus: true

        anchors.fill: parent
        Keys.forwardTo: [artViewLoader.item, toplevelhandler]

        Loader {
            id: artViewLoader
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
                //anchors.centerIn: parent
                id: clockLabel
                color: "white"
                font.bold: true
                font.pixelSize: parent.height
                text: d.timeString
            }
            Item {
                anchors { left: clockLabel.right; leftMargin: 20 }
                height: clock.height
                width: childrenRect.width
                Item {
                    width: childrenRect.width
                    height: parent.height/2
                    Text {
                        anchors.centerIn: parent
                        color: "white"
                        font.bold: true
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: clock.height/3
                        text: d.day
                    }
                }
                Item {
                    y: parent.height/2
                    width: childrenRect.width
                    height: parent.height/2
                    Text {
                        anchors.centerIn: parent
                        color: "white"
                        font.bold: true
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: clock.height/3
                        text: d.month
                    }
                }

            }
        }
        Component.onCompleted: {
            if (globalSettings.backdrop != "") {
                Qt.createQmlObject(globalSettings.backdrop + ' { anchors.fill: parent}', root)
            }
        }
    }

    Item {
        id: toplevelhandler
        focus: true
        Keys.onPressed: {
            switch(event.key) {
            case Qt.Key_F:
                globalSettings.fullscreen = !globalSettings.fullscreen
                break;
            case Qt.Key_Left:
                globalSettings.columnCount = Math.max(globalSettings.columnCount - 1, 1);
                break;
            case Qt.Key_Right:
                globalSettings.columnCount++;
                break;
            case Qt.Key_Escape:
                Qt.quit();
                break;
            case Qt.Key_F10:
                globalSettings.showViewItemCount = !globalSettings.showViewItemCount;
                break;
            default:
                console.log('Key not handled')
            }
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
        showTimer.start()
    }

    Item {
        z: 1
        visible: d.displayUnlicensed
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
            source: "qrc:///unlicensed.png"
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

    Timer {
        id: showTimer

        running: false
        repeat: false
        interval: 1
        onTriggered: {
            showAtCorrectSize()
        }
    }

    Timer {
        running: true
        interval: 60*1000
        onTriggered: {
            if (globalSettings.unlicensed) {
                d.displayUnlicensed = true
            }
        }
    }

    FPSMonitor {
        anchors { top: parent.top; right: parent.right }
    }
}
