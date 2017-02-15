import QtQuick 2.5
import PictureModel 1.0

import ".."

Rectangle {
    id: root
    property var effect
    property int modelIndex

    color: globalSettings.randomTapestryColour ? Qt.rgba(Math.random(255), Math.random(255), Math.random(255), 1.0) : "black"

    height: Math.ceil(width/imageModel.data(modelIndex, PictureModel.RatioRole))
    width: parent ? parent.width : 0

    Image {
        id: image
        opacity: globalSettings.fadeInImages ? 0 : 1.0
        anchors.fill: parent
        asynchronous: true
        fillMode: Image.PreserveAspectFit

        source: imageModel.data(modelIndex)

        mirror: globalSettings.randomlyMirrorArt && (Math.random() < 0.5)
        smooth: globalSettings.smoothArt

        sourceSize.height: globalVars.imageWidthOverride > 0 ? Math.ceil(globalVars.imageWidthOverride/imageModel.data(modelIndex, PictureModel.RatioRole)) : height
        sourceSize.width: globalVars.imageWidthOverride > 0 ? globalVars.imageWidthOverride : width

        Behavior on opacity {
            SequentialAnimation {
                ScriptAction { script: root.effect !== undefined ? root.effect.scheduleUpdate() : undefined }
                NumberAnimation { duration: 1000 }
            }
        }

        onStatusChanged: {
            if (status === Image.Ready) {
                opacity = globalSettings.artOpacity
            }
        }
    }

    Component.onCompleted: {
        modelIndex = Math.floor(Math.random()*imageModel.count)
        if (globalSettings.effect !== "" && Effects.validate(globalSettings.effect)) {
            var component = Qt.createComponent("VisualEffect.qml");
            component.status !== Component.Ready && console.log('Component failed with:' + effectDelegate.errorString())
            root.effect = component.createObject(root, { target: image, effect: globalSettings.effect })
        }
    }
}
