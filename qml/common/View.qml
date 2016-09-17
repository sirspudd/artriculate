import QtQuick 2.5

Item {
    id: root

    property var columnArray: []
    property var pictureDelegate: Component {
        ArtImage {}
    }

    function reset() {
        columnArray = []
    }

    anchors.fill: parent

    Timer {
        id: globalDeathTimer
        running: globalSettings.commonFeed && globalUtil.primed
        repeat: true
        interval: globalUtil.adjustedInterval
        onTriggered: columnArray[globalUtil.columnSelection()].shift()
    }

    Repeater {
        model: globalSettings.columnCount
        delegate: columnComponent
    }
}
