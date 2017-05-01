import QtQuick 2.6

Widget {
    width: itemCountLabel.width
    height: itemCountLabel.height

    Text {
        id: itemCountLabel
        font.pixelSize: widgetProperties.fontPixelSize
        text: "Items:" + globalUtil.itemCount
        color: "white"
    }
}
