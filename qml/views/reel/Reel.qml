import QtQuick 2.5
import Qt.labs.settings 1.0

// Forgive me
import "../.."

View {
    id: root

    property var pictureDelegate: Component {
        ReelImage {}
    }

    Settings {
        id: reelSettings
        category: "Reel"
        property bool deathTransition: false
        property int deathPeriod: 10000
        property real restingVelocity: 4
        property real velocityAccelIncrements: 0.3
    }

    QtObject {
        id: d
        property real t: 0
        property var priorImage
        property real velocity: 0
        property bool initialized: false
        property int imageBuffer: 1
        property real columnRatio: globalSettings.useGoldenRatio ? globalVars.goldenRatio : globalSettings.lessGoldenRatio
        property real columnWidth: root.width*globalUtil.columnWidthRatio(d.columnRatio, globalSettings.columnCount)

        function animationStep() {
            for(var i = columnArray.length - 1; i >= 0; i--) {
                columnArray[i].animationStep()
            }
        }

        function killLastImage() {
            if(!!priorImage) {
                priorImage.destroy()
                globalUtil.itemCount--
            }
            var col = columnArray[globalSettings.columnCount - 1]
            priorImage = col.imageArray.shift()
            reelSettings.deathTransition && priorImage.bowOut()
        }

        NumberAnimation on t { from: 0; to: 1; duration: 1000; loops: -1 }
        onTChanged: { animationStep(); }
    }

    Component {
        id: columnComponent

        Item {
            id: column

            property int columnIndex: index
            property var imageArray: []
            property var imageQueue: []
            property bool lastColumn: columnIndex === (globalSettings.columnCount - 1)

            function receptive() {
                return !imageArray.length || imageArray[imageArray.length - 1].y > -d.velocity
            }

            function addNewImage() {
                globalUtil.itemCount++
                addImage(pictureDelegate.createObject())
                imageArray.push(imageQueue.pop())
            }

            function addImage(image) {
                image.parent = column
                image.y = - image.height
                imageQueue.push(image)
            }

            function animationStep() {
                if (receptive()) {
                    if (columnIndex === 0
                            && !(globalSettings.itemLimit > 0 && globalSettings.itemLimit <= globalUtil.itemCount)) {
                        addNewImage()
                    }

                    if (imageQueue.length) {
                        var image = imageQueue.pop()
                        image.y = (imageArray.length ? imageArray[imageArray.length-1].y : 0) - image.height
                        imageArray.push(image)
                    }
                }

                if (imageArray.length) {
                    var image = imageArray[0]
                    var restingY = root.height - image.height
                    var prospectiveY = image.y + d.velocity
                    var nextColumn = columnArray[columnIndex+1]

                    if (image.y > root.height) {
                        imageArray.shift()
                        nextColumn.addImage(image)
                    } else if ((lastColumn || !nextColumn.receptive()) && prospectiveY >= restingY) {
                        image.y = restingY
                        if (lastColumn) {
                            deathTimer.start()
                            if(!d.initialized) {
                                d.initialized = true
                                d.velocity = reelSettings.restingVelocity
                            }
                        }
                    } else {
                        image.y = prospectiveY
                    }
                }

                for (var i = 1; i < imageArray.length; i++) {
                   var lowerImage = imageArray[i - 1];
                   var image = imageArray[i]
                   image.y = lowerImage.y - image.height
                }
            }

            Component.onCompleted: columnArray.push(this)

            x: d.columnWidth/globalUtil.columnWidthRatio(d.columnRatio, index)
            width: {
                var colWidth = d.columnWidth*Math.pow(d.columnRatio, index);
                lastColumn && (globalVars.imageWidthOverride = colWidth)
                return colWidth
            }
            anchors { top: parent.top; bottom: parent.bottom }
        }
    }

    // accel
    Timer {
        repeat: true
        running: !d.initialized
        interval: 100
        onTriggered: {
            d.velocity += reelSettings.velocityAccelIncrements
        }
    }

    // death
    Timer {
        id: deathTimer
        repeat: false
        running: false
        interval: reelSettings.deathPeriod
        onTriggered: {
            d.killLastImage()
        }
    }

    Keys.onDownPressed: {
        d.killLastImage()
    }
}
