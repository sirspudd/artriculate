pragma Singleton

import QtQuick 2.5

Item {
    property var names: ["Emboss", "Billboard", "GaussianBlur", "Wobble"]
    property var components: []
    property string randomEffectText: "Random"

    function indexOf(name) {
        if (name === randomEffectText)
            return Math.floor(Math.random()*components.length)
        else
            return names.indexOf(name)
    }

    function validate(name) {
        var valid = (name === randomEffectText) || (indexOf(name) !== -1)
        if (!valid) console.log('Requested effect: ' + name + ' does not exist')
        return valid
    }

    function getComponent(name) {
        var i = indexOf(name)
        return components[i]
    }

    Component.onCompleted: {
        names.forEach(function(name) {
            var comp = Qt.createComponent(name + ".qml")
            if (comp.status !== Component.Ready) {
                console.log('Component failed with:' + comp.errorString())
            } else {
                components.push(comp)
            }
        })
    }
}
