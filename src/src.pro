TEMPLATE = app

DESTDIR = ../

QT += qml quick dbus sql
CONFIG += c++11

DEFINES *= QT_USE_QSTRINGBUILDER

#CONFIG += box2d
box2d {
    include(../3rdparty/qml-box2d/box2d-static.pri)
}

contains(QT_CONFIG, static) {
    CONFIG += compiledResources
    DEFINES += STATIC_BUILD
    QTPLUGIN += windowplugin \
                qtquick2plugin \
                qmlsettingsplugin
    LIBPATH += $$[QT_INSTALL_QML]/QtQuick.2 $$[QT_INSTALL_QML]/QtQuick/Window.2 $$[QT_INSTALL_QML]/Qt/labs/settings
}

HEADERS += \
    picturemodel.h

SOURCES += main.cpp \
    picturemodel.cpp

RESOURCES += resources/resources.qrc

DISTFILES += \
    ../qml/qmldir \
    ../qml/unlicensed/unlicensed.png \
    ../qml/views/conveyor/Monty_python_foot.png \
    ../qml/3rdparty/backdrops/qml-presentation-visuals/particle.png \
    ../qml/3rdparty/backdrops/cells/noise.png \
    ../qml/3rdparty/effects/shaders/billboard.fsh \
    ../qml/3rdparty/effects/shaders/emboss.fsh \
    ../qml/3rdparty/effects/shaders/gaussianblur_h.fsh \
    ../qml/3rdparty/effects/shaders/gaussianblur_v.fsh

QMLFILES += \
    ../qml/main.qml \
    ../qml/widgets/Widget.qml \
    ../qml/widgets/FPS.qml \
    ../qml/widgets/Clock.qml \
    ../qml/widgets/ItemCount.qml \
    ../qml/widgets/Resolution.qml \
    ../qml/widgets/InfoTray.qml \
    ../qml/widgets/RebootReq.qml \
    ../qml/common/VisualEffect.qml \
    ../qml/common/ArtImage.qml \
    ../qml/common/View.qml \
    ../qml/physics/BoxBody.qml \
    ../qml/physics/ImageBoxBody.qml \
    ../qml/physics/ArtBoxBody.qml \
    ../qml/physics/RectangleBoxBody.qml \
    ../qml/views/well/WellDelegate.qml \
    ../qml/views/well/Well.qml \
    ../qml/views/cascade/Cascade.qml \
    ../qml/views/cascade/CascadeDelegate.qml \
    ../qml/views/conveyor/Conveyor.qml \
    ../qml/views/basic/Basic.qml \
    ../qml/views/reel/Reel.qml \
    ../qml/views/reel/ReelImage.qml \
    ../qml/views/procession/Procession.qml \
    ../qml/views/procession/ProcessionImage.qml \
    ../qml/views/simplelistview/SimpleListView.qml \
    ../qml/unlicensed/Unlicensed.qml \
    ../qml/3rdparty/effects/Effects.qml \
    ../qml/3rdparty/effects/Effect.qml \
    ../qml/3rdparty/effects/Billboard.qml \
    ../qml/3rdparty/effects/Emboss.qml \
    ../qml/3rdparty/effects/GaussianBlur.qml \
    ../qml/3rdparty/backdrops/qml-presentation-visuals/Swirl.qml \
    ../qml/3rdparty/backdrops/qml-presentation-visuals/BackgroundSwirls.qml \
    ../qml/3rdparty/backdrops/cells/cells.qml \

DISTFILES += $${QMLFILES}

for(qml_file, QMLFILES) {
    QMLCFILES+=$${qml_file}c
    system(qmlcachegen --target-architecture $$QT_ARCH --target-abi $${QT_BUILDABI} $${qml_file})
}

compiledResources {
    RESOURCES += $${DISTFILES} $${QMLCFILES}
    DEFINES += COMPILED_RESOURCES
} else {
    qml.path = /usr/share/artriculate/qml
    qml.files = ../qml/*

    INSTALLS += qml
}

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
