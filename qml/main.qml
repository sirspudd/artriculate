import QtQuick 2.5
import QtQuick.Window 2.2
import Qt.labs.settings 1.0
import PictureModel 1.0

Window {
    id: appWindow

    color: "black"

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
        property string currentViewFilename
        property string overrideViewFilename
        property bool displayUnlicensed: false

        function setView(view) {
            d.currentViewFilename = deriveViewPath(overrideViewFilename.length ? overrideViewFilename : view)
        }

        function deriveViewPath(view) {
            return view.toLowerCase() + "/" + view + ".qml"
        }

        onCurrentViewFilenameChanged: {
            globalUtil.reset()
        }
    }

    Settings {
        id: globalSettings
        property int columnCount: 6
        property int interval: 5

        property string effect: ""
        property string view: "Reel"
        property string backdrop: ""

        property bool smoothArt: false
        property bool randomlyMirrorArt: true
        property bool fullscreen: true
        property bool commonFeed: true
        property bool commonFeedRoundRobin: true
        property bool unlicensed: false
        property bool fadeInImages: true
        property bool useGoldenRatio: false
        property bool widgetTray: false

        property real artOpacity: 1.0
        property real lessGoldenRatio: 4/3

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
            z: 1
            anchors.fill: parent
        }

        Component.onCompleted: {
            if (globalSettings.backdrop != "") {
                Qt.createQmlObject(globalSettings.backdrop + ' { anchors.fill: parent }', root)
            }

            if (globalSettings.widgetTray) {
                Qt.createQmlObject('WidgetTray { z: 2; anchors { top: parent.top; right: parent.right } }', root)
            }

            if (globalSettings.unlicensed) {
                Qt.createQmlObject('Unlicensed { z: 3 }', root)
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

    Component.onCompleted: {
        showTimer.start()
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
}
