import QtQuick 2.5
import Box2D 2.0
import Qt.labs.settings 1.0

import ".."

Item {
    id: root

    signal togglePause
    signal next

    property var pictureDelegate: Component {
        ArtImage {}
    }

    property var effectDelegate: Component {
        VisualEffect {}
    }

    anchors.fill: parent

    Settings {
        id: basicSettings
        category: "Basic"

        property int animationDuration: 2000
        property int easingType: Easing.Linear
        property bool commonFeed: true
    }

    QtObject {
        id: d
        property int columnCount: generalSettings.columnCount
        property var columnArray: []
        property int primedColumns: 0

        function reset() {
            columnArray = []
            primedColumns = 0
        }

        onColumnCountChanged: {
            reset()
        }
    }

    Component {
        id: columnComponent

        Item {
            id: column

            x: width * index
            height: parent.height
            width: parent.width/generalSettings.columnCount

            Item {
                id: artworkStack

                property var headElement
                property var pictureArray: []
                property int artworkHeight: 0
                property int compoundArtworkHeight: 0
                property bool full: artworkHeight > root.height
                property bool initialized: false

                Component.onCompleted: {
                    d.columnArray.push(this)
                }

                onFullChanged: {
                    if (!initialized) {
                        initialized = true
                        d.primedColumns++
                    }
                }

                height: childrenRect.height
                width: parent.width

                function addImage() {
                    var image = pictureDelegate.createObject(artworkStack)

                    if (generalSettings.effect !== "" && Effects.validate(generalSettings.effect)) {
                        image.effect = effectDelegate.createObject(artworkStack, { target: image, effect: generalSettings.effect })
                    }

                    artworkHeight += image.height
                    compoundArtworkHeight += image.height
                    image.y = root.height - compoundArtworkHeight

                    pictureArray.push(image)
                    globalVars.itemCount++
                }

                function removeImage(image) {
                    if (image.effect) {
                        image.effect.destroy()
                    }
                    image.destroy()
                    globalVars.itemCount--
                }

                function shift() {
                    if (headElement) {
                        removeImage(headElement)
                    }
                    headElement = pictureArray.shift()
                    artworkHeight -= headElement.height

                    while (!full) {
                        addImage()
                    }

                    artworkStack.y += headElement.height
                }

                Timer {
                    id: populateTimer
                    running: !artworkStack.initialized
                    repeat: true
                    interval: 100
                    onTriggered: artworkStack.addImage()
                }

                Timer {
                    id: deathTimer
                    running: !basicSettings.commonFeed && artworkStack.initialized
                    repeat: true
                    interval: globalVars.adjustedInterval
                    onTriggered: artworkStack.shift()
                }

                Behavior on y {
                    NumberAnimation {
                        duration: Math.min(globalVars.adjustedInterval, basicSettings.animationDuration)
                        easing.type: basicSettings.easingType
                    }
                }
            }

            Connections {
                target: root
                onTogglePause: deathTimer.running = !deathTimer.running
                onNext: deathTimer.triggered()
            }
        }
    }

    Timer {
        id: globalDeathTimer
        running: basicSettings.commonFeed && (d.primedColumns === d.columnCount)
        repeat: true
        interval: globalVars.adjustedInterval
        onTriggered: d.columnArray[Math.floor(Math.random()*d.columnCount)].shift()
    }

    Repeater {
        model: d.columnCount
        delegate: columnComponent
    }

    Keys.onUpPressed: root.togglePause()
    Keys.onDownPressed: root.next()
}
