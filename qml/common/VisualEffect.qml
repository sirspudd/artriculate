import QtQuick
import ".."

Item {
    id: root
    property alias target: effectSource.sourceItem

    property string effect: "Random"
    property var effectObject

    function scheduleUpdate() { effectSource.scheduleUpdate() }

    transformOrigin: Item.TopLeft
    anchors.fill: target
    scale: target.scale

    ShaderEffectSource {
        id: effectSource
        smooth: true
        hideSource: true
        sourceItem: target
        live: false
    }

    Component.onCompleted: {
        effectObject = Effects.getComponent(effect).createObject(root, { "source": effectSource, "anchors.fill": root, "targetWidth": root.width, "targetHeight": root.height })
    }
}
