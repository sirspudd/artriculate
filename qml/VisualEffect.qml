import QtQuick 2.5
import "effects" as Effects

Item {
    property alias target: source.sourceItem

    anchors.fill: target
    ShaderEffectSource {
        id: source
        smooth: true
        hideSource: true
        sourceItem: target
    }

    Effects.Emboss {
        source: source
        anchors.fill: parent
        targetWidth: parent.width
        targetHeight: parent.height
    }
}
