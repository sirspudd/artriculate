import QtQuick 2.6

// Required for effortless web serving!
import ".."

Widget {
    text: "DB:" + nativeUtils.imageCollection.count
}
