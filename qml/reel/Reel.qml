import QtQuick 2.5
import Qt.labs.settings 1.0

import ".."

View {
    id: root

    property var pictureDelegate: Component {
        ReelImage {}
    }

    Settings {
        id: reelSettings
        category: "Reel"
        property int deathYawn: 5000
    }

    QtObject {
        id: d
        property var priorImage
        property real velocity: 0
        property bool initialized: false
        property int imageBuffer: 1
        property real columnRatio: globalSettings.useGoldenRatio ? globalVars.goldenRatio : globalSettings.lessGoldenRatio
        property real columnWidth: root.width*globalUtil.columnWidthRatio(d.columnRatio, globalSettings.columnCount)

        function animationStep() {
            columnArray.forEach(function(column) { column.animationStep(); })
        }

        function killLastImage() {
            if(!!priorImage) {
                priorImage.destroy()
                globalUtil.itemCount--
            }
            var col = columnArray[globalSettings.columnCount - 1]
            priorImage = col.imageArray.shift()
        }
    }

    Component {
        id: columnComponent

        Item {
            id: column

            property int columnIndex: index
            property var imageArray: []
            property var imageQueue: []

            function stackHeight(imageIndex) {
                var height = 0
                for(var i = 0; i < imageIndex; i++) {
                    height += imageArray[i].height
                }
                return height
            }

            function receptive() {
                return imageQueue.length < d.imageBuffer
            }

            function addImage(image) {
                image.parent = column
                image.y = - image.height
                imageQueue.push(image)
            }

            function animationStep() {
                if (!imageArray.length || imageArray[imageArray.length - 1].y > -1) {
                    if (imageQueue.length) {
                        imageArray.push(imageQueue.pop())
                    } else if (columnIndex === 0) {
                        globalUtil.itemCount++
                        addImage(pictureDelegate.createObject())
                        imageArray.push(imageQueue.pop())
                    }
                }

                for (var i = 0; i < imageArray.length; i++) {
                    var image = imageArray[i]
                    var restingY = root.height - image.height - stackHeight(i)
                    var prospectiveY = image.y + d.velocity
                    var lastColumn = columnIndex === (globalSettings.columnCount - 1)

                    if (image.y > root.height) {
                        imageArray.shift()
                        columnArray[columnIndex+1].addImage(image)
                    } else if (( lastColumn || !columnArray[columnIndex+1].receptive()) && prospectiveY >= restingY) {
                        image.y = restingY
                        if (lastColumn) {
                            deathTimer.start()
                            if(!d.initialized) {
                                d.initialized = true
                                d.velocity = 4
                            }
                        }
                    } else {
                        image.y = prospectiveY
                    }
                }
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

    // feed
    Timer {
        repeat: true
        running: true
        interval: 100/6
        onTriggered: d.animationStep()
    }

    // accel
    Timer {
        repeat: true
        running: !d.initialized
        interval: 100
        onTriggered: {
            d.velocity += 0.1
        }
    }

    // death
    Timer {
        id: deathTimer
        repeat: false
        running: false
        interval: reelSettings.deathYawn
        onTriggered: {
            d.killLastImage()
        }
    }

    Keys.onDownPressed: {
        d.killLastImage()
    }
}
