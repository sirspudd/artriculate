import QtQuick 2.5
import PictureModel 1.0

import ".."

Item {
    id: root
    property var effect
    property int modelIndex

    property alias asynchronous: image.asynchronous
    property alias source: image.source

    //color: Qt.rgba(Math.random(255), Math.random(255), Math.random(255), 1.0)

    height: width*nativeUtils.imageCollection.data(modelIndex, PictureModel.SizeRole).height/nativeUtils.imageCollection.data(modelIndex, PictureModel.SizeRole).width
    width: parent ? parent.width : 0

    Image {
        id: image
        cache: false
        opacity: globalSettings.fadeInImages ? 0 : 1.0

        height: globalVars.imageWidthOverride > 0 ? Math.ceil(globalVars.imageWidthOverride*nativeUtils.imageCollection.data(modelIndex, PictureModel.SizeRole).height/nativeUtils.imageCollection.data(modelIndex, PictureModel.SizeRole).width) : nativeUtils.imageCollection.data(modelIndex, PictureModel.SizeRole).height
        width: globalVars.imageWidthOverride > 0 ? globalVars.imageWidthOverride : nativeUtils.imageCollection.data(modelIndex, PictureModel.SizeRole).width

        transformOrigin: Item.TopLeft
        scale: root.width/image.width

        asynchronous: true
        fillMode: Image.PreserveAspectFit

        source: nativeUtils.imageCollection.data(modelIndex)

        mirror: globalSettings.randomlyMirrorArt && (Math.random() < globalSettings.randomlyMirrorArtFreq)
        smooth: globalSettings.smoothArt
        mipmap: !globalSettings.smoothArt

        sourceSize.height: height
        sourceSize.width: width

        Behavior on opacity {
            enabled: image.asynchronous
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
        modelIndex = nativeUtils.imageCollection.requestIndex()
        if (globalSettings.effect !== "" && Effects.validate(globalSettings.effect)) {
            var component = Qt.createComponent("VisualEffect.qml");
            component.status !== Component.Ready && console.log('Component failed with:' + component.errorString())
            root.effect = component.createObject(root, { target: image, effect: globalSettings.effect })
        }
    }

    Component.onDestruction: nativeUtils.imageCollection.retireIndex(modelIndex)
}
