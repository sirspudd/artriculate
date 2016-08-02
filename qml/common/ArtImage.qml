import QtQuick 2.5

Image {
    property var effect

    fillMode: Image.PreserveAspectFit
    source: imageModel.randomPicture()
    width: parent.width
    mirror: generalSettings.randomlyMirrorArt && (Math.random() < 0.5)
    smooth: generalSettings.smoothArt

    sourceSize.height: height
    sourceSize.width: width
}
