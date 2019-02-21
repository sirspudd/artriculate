import QtQuick 2.5

import PictureModel 1.0

// Forgive me
import "../.."

ListView {
    anchors.fill: parent

    delegate: ArtImage {
        source: path
        height: size.height
        width: size.width
    }
    model: globalUtil.imageModel

    PictureModel {
        id: imageModel
        Component.onCompleted: {
            globalUtil.imageModel = imageModel
        }
    }
}
