import QtQuick 2.5

Image {
    property var effect

    fillMode: Image.PreserveAspectCrop
    source: imageModel.randomPicture()
    width: parent.width
    mirror: globalSettings.randomlyMirrorArt && (Math.random() < 0.5)
    smooth: globalSettings.smoothArt

    sourceSize.height: height
    sourceSize.width: width
}
