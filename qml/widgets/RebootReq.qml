import QtQuick 2.5

// Required for effortless web serving!
import ".."

Image {
  visible: nativeUtils.rebootRequired
  source: "qrc:///buuf/Free Your Mind.png"
}
