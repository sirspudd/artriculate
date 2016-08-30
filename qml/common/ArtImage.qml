import QtQuick 2.5
import PictureModel 1.0

Rectangle {
    property var effect
    property int modelIndex

    color: "black"

    height: Math.ceil(width/imageModel.data(modelIndex, PictureModel.RatioRole))
    width: parent.width

    Image {
        opacity: 0
        anchors.fill: parent
        asynchronous: true
        fillMode: Image.PreserveAspectFit

        source: imageModel.data(modelIndex)

        mirror: globalSettings.randomlyMirrorArt && (Math.random() < 0.5)
        smooth: globalSettings.smoothArt

        sourceSize.height: height
        sourceSize.width: width

        Behavior on opacity {
            NumberAnimation { duration: 1000 }
        }

        onStatusChanged: {
            if (status === Image.Ready) {
                opacity = 1
            }
        }
    }

    Component.onCompleted: {
        modelIndex = Math.floor(Math.random()*imageModel.count)
    }
}
