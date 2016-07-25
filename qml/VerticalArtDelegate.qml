import QtQuick 2.5

ArtDelegate {
    height: parent.height/settings.columnCount
    width: implicitWidth/implicitHeight*height
    x: parent.effectiveXOffset + (parent.width - width)/2
}
