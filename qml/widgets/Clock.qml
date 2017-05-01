import QtQuick 2.6

Widget {
    id: root

    width: childrenRect.width
    height: clockLabel.height

    QtObject {
        id: d
        property string timeString
        property int day
        property int month

        function timeChanged() {
            var date = new Date;
            timeString = Qt.formatDateTime(date, "hh:mm")
            day = Qt.formatDateTime(date, "dd")
            month = Qt.formatDateTime(date, "MM")
        }
    }

    Timer {
        interval: 10*1000; running: true; repeat: true;
        onTriggered: d.timeChanged()
    }

    Text {
        //anchors.centerIn: parent
        id: clockLabel
        color: "white"
        font.bold: true
        font.pixelSize: 100
        text: d.timeString
    }
    Item {
        anchors { left: clockLabel.right; leftMargin: 20 }
        height: root.height
        width: childrenRect.width
        Item {
            width: childrenRect.width
            height: parent.height/2
            Text {
                anchors.centerIn: parent
                color: "white"
                font.bold: true
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: root.height/3
                text: d.day
            }
        }
        Item {
            y: parent.height/2
            width: childrenRect.width
            height: parent.height/2
            Text {
                anchors.centerIn: parent
                color: "white"
                font.bold: true
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: root.height/3
                text: d.month
            }
        }

    }
}
