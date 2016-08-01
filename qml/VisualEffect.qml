import QtQuick 2.5
import "effects"

Item {
    id: root
    property alias target: effectSource.sourceItem

    property string effect: "Random"
    property var effectObject

    anchors.fill: target

    ShaderEffectSource {
        id: effectSource
        smooth: settings.smoothedEffects
        hideSource: true
        sourceItem: target
    }

    Component.onCompleted: {
        effectObject = Effects.getComponent(effect).createObject(root, { "source": effectSource, "anchors.fill": root, "targetWidth": root.width, "targetHeight": root.height })
    }
}
