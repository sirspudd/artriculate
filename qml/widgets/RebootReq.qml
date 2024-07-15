import QtQuick

// Required for effortless web serving!

Image {
  visible: nativeUtils.rebootRequired
  source: "qrc:///buuf/Free Your Mind.png"
}
