TEMPLATE = app

QT += qml quick dbus sql
CONFIG += c++11

DEFINES *= QT_USE_QSTRINGBUILDER

SOURCES += src/main.cpp \
    src/picturemodel.cpp \
    src/helperfunctions.cpp

RESOURCES += qml/qml.qrc resources/resources.qrc

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

target.path = /usr/bin

desktop.path = /usr/share/applications
desktop.files += resources/artriculate.desktop

icon.path = /usr/share/icons/hicolor/128x128/apps
icon.files += resources/artriculate.png

INSTALLS += target desktop icon

# Default rules for deployment.
include(deployment.pri)

HEADERS += \
    src/picturemodel.h \
    src/helperfunctions.h \
    src/filereader.h
