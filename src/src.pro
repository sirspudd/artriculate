TEMPLATE = app

QT += qml quick dbus sql
CONFIG += c++11

DEFINES *= QT_USE_QSTRINGBUILDER

HEADERS += \
    picturemodel.h \
    filereader.h

SOURCES += main.cpp \
    picturemodel.cpp

RESOURCES += resources/resources.qrc

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

TARGET = artriculate-bin
target.path = /usr/bin

desktop.path = /usr/share/applications
desktop.files += resources/artriculate.desktop

icon.path = /usr/share/icons/hicolor/128x128/apps
icon.files += resources/artriculate.png

systemd.path = /usr/lib/systemd/system
systemd.files += resources/artriculate@.service

INSTALLS += target desktop icon systemd
