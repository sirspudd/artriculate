import QtQuick 2.5

ArtDelegate {
    height: implicitHeight/implicitWidth*width
    width: parent.width
    onXChanged: x = 0
}
