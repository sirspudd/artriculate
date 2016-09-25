import QtQuick 2.5
import ".."

Item {
    id: root
    property alias target: effectSource.sourceItem

    property string effect: "Random"
    property var effectObject

    function scheduleUpdate() { effectSource.scheduleUpdate() }

    anchors.fill: target

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
