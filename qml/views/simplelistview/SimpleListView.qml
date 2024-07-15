import QtQuick

// Forgive me

ListView {
    QtObject {
        id: d
        property bool settled: false
    }

    anchors.fill: parent

    delegate: Image {
        source: path
        height: size.height
        width: size.width
        Component.onDestruction: {
            d.settled ? nativeUtils.imageCollection.retireIndex(index) : undefined
        }
    }
    model: nativeUtils.imageCollection

    Component.onCompleted: {
        nativeUtils.imageCollection.assumeLinearAccess()
        d.settled = true
    }
}
