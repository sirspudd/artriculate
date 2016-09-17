import QtQuick 2.5
import Qt.labs.settings 1.0

import ".."

View {
    id: root

    Settings {
        id: basicSettings
        category: "Basic"

        property int animationDuration: 2000
        property int easingType: Easing.Linear
    }

    Component {
        id: columnComponent

        Item {
            id: column

            x: width * index
            height: parent.height
            width: parent.width/globalSettings.columnCount

            Item {
                id: artworkStack

                property var headElement
                property var pictureArray: []
                property int artworkHeight: 0
                property int compoundArtworkHeight: 0
                property bool full: artworkHeight > root.height
                property bool initialized: false

                Component.onCompleted: {
                    columnArray.push(this)
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

                    artworkHeight += image.height
                    compoundArtworkHeight += image.height
                    image.y = root.height - compoundArtworkHeight

                    pictureArray.push(image)
                    globalUtil.itemCount++
                }

                function removeImage(image) {
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
                    running: !globalSettings.commonFeed && artworkStack.initialized
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
        }
    }

    Keys.onUpPressed: globalSettings.interval++
    Keys.onDownPressed: globalSettings.interval = Math.max(1, globalSettings.interval - 1)
}
