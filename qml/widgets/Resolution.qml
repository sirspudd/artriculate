import QtQuick 2.6

Widget {
    width: resolutionLabel.width
    height: resolutionLabel.height

    Text {
        id: resolutionLabel
        font.pixelSize: 100
        text: screenSize.width + "x" + screenSize.height
        color: "white"
    }
}
