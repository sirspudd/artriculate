TEMPLATE = app

QT += qml quick dbus
CONFIG += c++11

SOURCES += src/main.cpp \
    src/picturemodel.cpp

RESOURCES += qml/qml.qrc resources/resources.qrc

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

target.path = /usr/bin

desktop.path = /usr/share/applications
desktop.files += resources/artriculate.desktop

INSTALLS += target desktop

# Default rules for deployment.
include(deployment.pri)

HEADERS += \
    src/picturemodel.h
