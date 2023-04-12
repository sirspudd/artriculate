import QtQuick

// Required for effortless web serving!
import ".."

Widget {
    text: "DB:" + nativeUtils.imageCollection.count
}
