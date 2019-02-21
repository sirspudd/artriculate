import QtQuick 2.5

import PictureModel 1.0

// Forgive me
import "../.."

ListView {
    delegate: ArtImage {}
    model: globalUtil.imageModel

    PictureModel {
        id: imageModel
        Component.onCompleted: {
            globalUtil.imageModel = imageModel
        }
    }
}
