import QtQuick 2.5

import "../.."

Item {
    id: root

    property var imageArray: []

    function animationStep() {
        var lastImage = d.headImageArray[0]

        if (lastImage === undefined || lastImage.y > 0) {
            globalUtil.itemCount++
            var newItem = d.pictureDelegate.createObject(root)
            newItem.y = !!d.headImageArray[0]
                    ? d.headImageArray[0].y - newItem.height
                    : - newItem.height
            imageArray.push(newItem)
            d.headImageArray[0] = newItem
        }

        imageArray.forEach(function(image) { image.advance() })
    }

    QtObject {
        id: d
        property real speed: 10
        property int startingPoint: 0
        property real t: 0
        property real columnRatio: globalSettings.useGoldenRatio ? globalVars.goldenRatio : globalSettings.lessGoldenRatio
        property var imageArray: []
        property var colWidthArray: []
        property var xposArray: []
        property var headImageArray: []

        property var pictureDelegate: Component {
            ArtImage {
                property int columnIndex: 0

                function advance() {
                    if (y > root.height) {
                        if (globalSettings.columnCount - columnIndex < 1) {
                            imageArray.shift()
                            visible = false
                            destroy();
                            d.speed = 1
                        } else {
                            columnIndex += 1
                            y = !!d.headImageArray[columnIndex] ? d.headImageArray[columnIndex].y - height : - height
                            d.headImageArray[columnIndex] = this
                        }
                    } else {
                        y += d.speed
                    }
                }

                width: d.colWidthArray[columnIndex]
                x: d.xposArray[columnIndex]

                onHeightChanged: {
                    y = !!d.headImageArray[columnIndex] ? d.headImageArray[columnIndex].y - height : - height
                }
            }
        }

        NumberAnimation on t { from: 0; to: 1; duration: 1000; loops: -1 }
        onTChanged: { root.animationStep(); }

        Component.onCompleted: {
            var baseUnit = root.width*globalUtil.columnWidthRatio(d.columnRatio, globalSettings.columnCount)
            for(var i = 0; i < globalSettings.columnCount; i++) {
                if (i == (globalSettings.columnCount-1)) {
                    var finalColWidth = root.width - colWidthArray.reduce(function(a,b){ return a+b; }, 0)
                    colWidthArray.push(finalColWidth)
                    globalVars.imageWidthOverride = finalColWidth
                } else {
                    colWidthArray.push(Math.round(baseUnit*Math.pow(d.columnRatio, i)))
                }

                xposArray.push(i === 0 ? 0 : xposArray[i-1] + colWidthArray[i-1])
            }
        }
    }

    Connections {
        target: globalSettings
        onColumnCountChanged: console.log('Col count:' + globalSettings.columnCount)
    }
}
