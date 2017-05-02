import QtQuick 2.0

Item {
    id: root

    Image {
        id: noiseImage
        source: "noise.png";
        visible: false
    }

    ShaderEffect {
        id: effect
        anchors.fill: parent
        property real time
        property real xRes: width
        property real yRes: height
        property real aspect: xRes / yRes
        property real cells: 15.0
        property real verticalCells: cells / aspect;
        property real yOffset: (verticalCells % 1.0) / verticalCells * 0.5;
        property variant noiseTexture: noiseImage
        NumberAnimation {
            target: effect
            property: "time"
            duration: 1000 * 60 * 5
            from: 0
            to: 60 * 5
            loops: Animation.Infinite
            running: true
        }

        fragmentShader: "
#ifdef GL_ES
precision highp float;
precision lowp sampler2D;
#endif

uniform highp float xRes;
uniform highp float yRes;
uniform highp float time;
varying highp vec2 qt_TexCoord0;
uniform sampler2D noiseTexture;
uniform float aspect;
uniform float cells;
uniform float verticalCells;
uniform float yOffset;

void main()
{
    vec2 screenUv = qt_TexCoord0 - vec2(0.0, yOffset);
    vec2 t = screenUv * vec2(cells, verticalCells);
    vec2 cellUv = fract(t);
    vec2 cellCoord = t - cellUv;
    vec2 normalizedCellCoord = cellCoord / cells;
    float noise = texture2D(noiseTexture, normalizedCellCoord + vec2(0.11)).r;
//    float noise2 = texture2D(noiseTexture, normalizedCellCoord - vec2(0.13)).r;
    float angle = noise * 30.0 + time * (0.5 + noise);
    float scale = 1.0 + noise * 2.0;
    float ca = cos(angle) * scale;
    float sa = sin(angle) * scale;
    mat2 rotate = mat2(ca, -sa,
                       sa, ca);
    vec2 rotatedCellUv = rotate * (cellUv - 0.5);
    rotatedCellUv.x = fract(rotatedCellUv.x);
    float sharpness = 20.0 * scale / xRes;
    float v = smoothstep(0.25 - sharpness, 0.25, rotatedCellUv.x) -
              smoothstep(0.75 - sharpness, 0.75, rotatedCellUv.x);

    float dim = 0.9 - pow(length(cellUv - 0.5), 3.2) * 2.5;
    float borderWidth = 0.04;
    if (cellUv.x > 1.0 - borderWidth || cellUv.y > 1.0 - borderWidth)
        dim = 0.0;
    if (cellUv.x < borderWidth || cellUv.y < borderWidth)
        dim = 0.0;

    v *= dim;
    gl_FragColor = vec4(v, v, v, 1.0);
}"
    }
}
