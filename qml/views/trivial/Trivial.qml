import QtQuick 2.5

import "../.."

import PictureModel 1.0

Item {
    id: root

    function animationStep() {
        var fullyLoaded = true
        for (var i = globalSettings.columnCount - 1; i >= 0; i--) {
            var col = d.imageArray[i]

            var tailItem = col[col.length-1]
            var headItem = col[0]

            var fullCanvas = !!tailItem && (tailItem.y <= -tailItem.height)
            var overloadedCanvas = fullCanvas && (tailItem.y < -headItem.height)

            if ((!d.initialized && !fullCanvas) || (i == 0) && !overloadedCanvas && (globalSettings.itemLimit < 0 || (globalUtil.itemCount < globalSettings.itemLimit))) {
                globalUtil.itemCount++
                tailItem = d.pictureDelegate.createObject(root)
                tailItem.loaded.connect(function() { d.loadedImageCount += 1 } )
                tailItem.columnIndex = i
                col.push(tailItem)
            }

            if (!d.initialized) {
                fullyLoaded = fullyLoaded  && fullCanvas
                continue
            }

            if (d.imagesLoaded && (overloadedCanvas || d.animating[i])) {
                feedTimer.restart()
                d.animating[i] = true
                for (var j = 0; j < col.length; j++) {
                    var item = col[j]
                    if (item.y > root.height) {
                        d.animating[i] = false
                        item = d.imageArray[i].shift()
                        if (globalSettings.columnCount - i > 1) {
                            item.columnIndex = i + 1
                            d.imageArray[i + 1].push(item)
                        } else {
                            item.destroy();
                            globalUtil.itemCount--
                        }
                        d.grainsOfSand = 0
                        d.velocity = 0
                        d.considerNextMove = false
                        return
                    } else {
                        item.y += d.velocity
                    }
                }
                d.grainsOfSand += 0.02
                d.velocity = Math.pow(d.grainsOfSand, 2)
                return;
            }
        }

        if (!d.initialized && fullyLoaded) {
            d.initialized = true
            background.color = "black"
            return
        }

        d.animating[0] = true
    }

    Rectangle {
        id: background
        color: "white"
        anchors.fill: parent
    }

    Timer {
        id: feedTimer
        interval: 2000
        running: false
        repeat: false
        onTriggered: {
            d.considerNextMove = true
        }
    }

    QtObject {
        id: d

        property bool considerNextMove: true

        property real velocity: 0
        property real grainsOfSand: 0

        property int loadedImageCount: 0
        property bool imagesLoaded: loadedImageCount > 0 && (loadedImageCount >= globalUtil.itemCount)

        property bool incoming: false
        property bool initialized: globalSettings.itemLimit > -1 ? true : false
        property real t: 0
        property real columnRatio: globalSettings.useGoldenRatio ? globalVars.goldenRatio : globalSettings.lessGoldenRatio

        property var imageArray: []
        property var colWidthArray: []
        property var xposArray: []
        property var animating: []

        property var pictureDelegate: Component {
            ArtImage {
                property int columnIndex: 0

                function considerY() {
                    var col = d.imageArray[columnIndex]
                    var originatingHeight = d.initialized ? -height : root.height - height
                    y = !!col[col.length - 1] ? col[col.length - 1].y - height : originatingHeight
                }

                width: d.colWidthArray[columnIndex]
                x: d.xposArray[columnIndex]

                onHeightChanged: {
                    considerY()
                }

                /*
                ShaderEffect {
                    z: 1
                    width: src.width; height: src.height
                    property variant src: artwork
                    vertexShader: "
                                  uniform highp mat4 qt_Matrix;
                                  attribute highp vec4 qt_Vertex;
                                  attribute highp vec2 qt_MultiTexCoord0;
                                  varying highp vec2 coord;
                                  void main() {
                                      coord = qt_MultiTexCoord0;
                                      gl_Position = qt_Matrix * qt_Vertex;
                                  }"
                    fragmentShader: "
                                  varying highp vec2 coord;
                                  uniform sampler2D src;
                                  uniform lowp float qt_Opacity;
                                  void main() {
                                      lowp vec4 tex = texture2D(src, coord);
                                      gl_FragColor = vec4(vec3(dot(tex.rgb,
                                                          vec3(0.344, 0.5, 0.156))),
                                                               tex.a) * qt_Opacity;
                                  }"
                }*/
            }
        }

        NumberAnimation on t { running: d.considerNextMove; from: 0; to: 1; duration: 1000; loops: -1 }
        onTChanged: { root.animationStep(); }

        Component.onCompleted: {
            var baseUnit = root.width*globalUtil.columnWidthRatio(d.columnRatio, globalSettings.columnCount)
            for(var i = 0; i < globalSettings.columnCount; i++) {
                if (i == (globalSettings.columnCount-1)) {
                    var finalColWidth = root.width - colWidthArray.reduce(function(a,b){ return a+b; }, 0)
                    colWidthArray.push(finalColWidth)
                    globalVars.imageWidthOverride = finalColWidth
                } else {
                    colWidthArray.push(Math.round(baseUnit*Math.pow(d.columnRatio, i)))
                }

                xposArray.push(i === 0 ? 0 : xposArray[i-1] + colWidthArray[i-1])
                imageArray[i] = new Array;
                d.animating[i] = false
            }
        }
    }

    Connections {
        target: globalSettings
        function onColumnCountChanged() { console.log('Col count:' + globalSettings.columnCount) }
    }
}
