import QtQuick

Item {
    id: toplevel
    z: 1
    anchors.fill: parent

    QtObject {
        id: d
        property bool running: mug.visible
    }

    function calculateBounds() {
        xReboundPoint = toplevel.width - mug.width
        yReboundPoint = toplevel.height - mug.height
        console.log("xReboundPoint" + xReboundPoint)
        console.log("yReboundPoint" + yReboundPoint)
        freeRangeMugEngine.restart();
    }

    Column {
        id: muggins

        spacing: -50

        Text {
            z: 1
            color: "white"
            font.pixelSize: mug.height/5
            text: "UNLICENCED"
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Image {
            id: mug
            fillMode: Image.PreserveAspectFit
            height: toplevel.height/10
            source: "unlicensed.png"
            anchors.horizontalCenter: parent.horizontalCenter
            onWidthChanged: {
                calculateBounds();
            }
        }

        Text {
            z: 1
            color: "white"
            font.pixelSize: mug.height/5
            text: "STARVING ARTIST"
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }



    // width is initially zero, and an animator started against it against this value is not going to get a clue
    property double xReboundPoint
    property double yReboundPoint
    property double fixedSpeedFactor: 5

    onWidthChanged: {
        calculateBounds();
    }
    ParallelAnimation {
        id: freeRangeMugEngine
        SequentialAnimation {
            XAnimator {
                target: muggins;
                from: 0
                to: xReboundPoint
                duration: xReboundPoint * fixedSpeedFactor
            }
            XAnimator {
                target: muggins;
                from: xReboundPoint
                to: 0
                duration: xReboundPoint * fixedSpeedFactor
            }
            loops: Animation.Infinite
        }
        SequentialAnimation {
            YAnimator {
                target: muggins;
                from: 0
                to: yReboundPoint
                duration: yReboundPoint * fixedSpeedFactor
            }
            YAnimator {
                target: muggins;
                from: yReboundPoint
                to: 0
                duration: yReboundPoint * fixedSpeedFactor
            }
            loops: Animation.Infinite
        }
        RotationAnimator {
            target: muggins;
            from: 0;
            to: 360
            duration: 2000
            loops: Animation.Infinite
        }
        loops: Animation.Infinite
    }

    Component.onCompleted: {
        console.log("height:" + toplevel.height)
        console.log("width:" + toplevel.width)
    }
}
