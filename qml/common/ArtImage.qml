import QtQuick 2.5
import PictureModel 1.0

Image {
    property var effect
    property int modelIndex

    asynchronous: true
    fillMode: Image.PreserveAspectFit
    //fillMode: Image.PreserveAspectCrop

    source: imageModel.data(modelIndex)

    height: width/imageModel.data(modelIndex, PictureModel.RatioRole)
    width: parent.width

    mirror: globalSettings.randomlyMirrorArt && (Math.random() < 0.5)
    smooth: globalSettings.smoothArt

    sourceSize.height: height
    sourceSize.width: width

    Component.onCompleted: {
        modelIndex = Math.floor(Math.random()*imageModel.count)
    }
}
