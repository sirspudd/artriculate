import QtQuick 2.5
import Qt.labs.settings 1.0

import ".."

View {
    id: root

    property var pictureDelegate: Component {
        ProcessionImage {}
    }

    QtObject {
        id: d
        property bool initialAcceleration: true
        property int count: 0
        property real velocity: 0
        property int imageBuffer: Math.sqrt(globalSettings.columnCount) + 1
        property real columnRatio: globalSettings.useGoldenRatio ? globalVars.goldenRatio : globalSettings.lessGoldenRatio
        property real columnWidth: root.width*globalUtil.columnWidthRatio(d.columnRatio, globalSettings.columnCount)

        function animationStep() {
            columnArray.forEach(function(column) { column.animationStep(); })
        }
    }

    Component {
        id: columnComponent

        Item {
            id: column

            property int columnIndex: index
            property var imageArray: []
            property var imageQueue: []

            function receptive() {
                return imageQueue.length < d.imageBuffer
            }

            function addImage(image) {
                image.parent = column
                image.y = - image.height
                imageQueue.push(image)
            }

            function animationStep() {
                if (d.initialAcceleration && (++d.count % 10 === 0)) {
                    d.count = 0
                    d.velocity += 0.1
                }

                if (!imageArray.length || imageArray[imageArray.length - 1].y > -1) {
                    if (imageQueue.length) {
                        imageArray.push(imageQueue.pop())
                    } else if (columnIndex === 0) {
                        globalUtil.itemCount++
                        addImage(pictureDelegate.createObject())
                        imageArray.push(imageQueue.pop())
                    }
                }

                imageArray.forEach(function(image) {
                    image.y = image.y + d.velocity
                    if (image.y > root.height) {
                        imageArray.shift()
                        if (columnIndex === (globalSettings.columnCount - 1)) {
                            if (image.primed) {
                                image.destroy()
                                globalUtil.itemCount--
                            } else {
                                d.initialAcceleration = false
                                d.velocity = 1
                                image.primed = true
                                column.addImage(image)
                            }
                        } else {
                            var nextColumn = columnArray[columnIndex+1]
                            if (nextColumn.receptive())
                                nextColumn.addImage(image)
                            else
                                column.addImage(image)
                        }
                    }
                })
            }

            Component.onCompleted: columnArray.push(this)

            x: d.columnWidth/globalUtil.columnWidthRatio(d.columnRatio, index)
            width: {
                var colWidth = d.columnWidth*Math.pow(d.columnRatio, index);
                (index === (globalSettings.columnCount - 1)) && (globalVars.imageWidthOverride = colWidth)
                return colWidth
            }
            anchors { top: parent.top; bottom: parent.bottom }
        }
    }

    Timer {
        repeat: true
        running: true
        interval: 100/6
        onTriggered: d.animationStep()
    }

    Keys.onUpPressed: globalSettings.interval++
    Keys.onDownPressed: globalSettings.interval = Math.max(1, globalSettings.interval - 1)
}
