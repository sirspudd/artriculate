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
            var col = columnArray[columnArray.length - 1]
            col.imageArray.length && (col.imageArray[0].reviewed = true)
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

            function receptive(image) {
                return !d.initialized || !imageArray.length || imageArray[imageArray.length - 1].y >= (-d.velocity - image.height*d.columnRatio)
            }

            function addNewImage() {
                globalUtil.itemCount++
                addImage(pictureDelegate.createObject())
            }

            function addImage(image) {
                image.parent = column
                image.y = (imageArray.length ? imageArray[imageArray.length-1].y : 0) - image.height
                imageArray.push(image)
            }

            function animationStep() {
                if (columnIndex === 0
                        && !(globalSettings.itemLimit > 0 && globalSettings.itemLimit <= globalUtil.itemCount)
                        && (!imageArray.length || imageArray[imageArray.length-1].y > -d.velocity))
                {
                    addNewImage()
                }

                if (imageArray.length) {
                    var image = imageArray[0]
                    var restingY = root.height - image.height
                    var prospectiveY = image.y + d.velocity
                    var nextColumn = columnArray[columnIndex+1]

                    if (image.y > root.height) {
                        imageArray.shift()
                        if (image.reviewed) {
                            image.destroy()
                            globalUtil.itemCount--
                        } else {
                            nextColumn.addImage(image)
                        }
                    } else if ((!nextColumn || !nextColumn.receptive(image))
                               && prospectiveY >= restingY
                               && !image.reviewed) {
                        image.y = restingY
                        if (!nextColumn) {
                            if(!d.initialized) {
                                d.initialized = true
                                d.velocity = reelSettings.restingVelocity
                            }
                            deathTimer.start()
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
                !columnArray[columnIndex+1] && (globalVars.imageWidthOverride = colWidth)
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
