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
    }

    QtObject {
        id: d
        property var columnArray: []

        function reset() {
            columnArray = []
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
                        globalUtil.registerColumnPrimed()
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
                    globalUtil.itemCount++
                }

                function removeImage(image) {
                    if (image.effect) {
                        image.effect.destroy()
                    }
                    image.destroy()
                    globalUtil.itemCount--
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
                    running: !generalSettings.commonFeed && artworkStack.initialized
                    repeat: true
                    interval: globalUtil.adjustedInterval
                    onTriggered: artworkStack.shift()
                }

                Behavior on y {
                    enabled: artworkStack.initialized
                    NumberAnimation {
                        duration: Math.min(globalUtil.adjustedInterval, basicSettings.animationDuration)
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
        running: generalSettings.commonFeed && globalUtil.primed
        repeat: true
        interval: globalUtil.adjustedInterval
        onTriggered: d.columnArray[globalUtil.columnSelection()].shift()
    }

    Repeater {
        model: globalUtil.columnCount
        delegate: columnComponent
        onModelChanged: d.reset()
    }

    Keys.onUpPressed: generalSettings.interval++
    Keys.onDownPressed: generalSettings.interval = Math.max(0, generalSettings.interval - 1)
}
