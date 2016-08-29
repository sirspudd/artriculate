import QtQuick 2.5

import ".."

ListView {
    delegate: ArtImage {
        source: path
        height: size.height
        width: size.width
    }
    model: imageModel
}
