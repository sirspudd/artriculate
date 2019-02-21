import QtQuick 2.5

import PictureModel 1.0

// Forgive me
import "../.."

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
            d.settled ? globalUtil.imageModel.retireIndex(index) : undefined
        }
    }
    model: globalUtil.imageModel

    PictureModel {
        id: imageModel
        Component.onCompleted: {
            imageModel.assumeLinearAccess()
            globalUtil.imageModel = imageModel
            d.settled = true
        }
    }
}
