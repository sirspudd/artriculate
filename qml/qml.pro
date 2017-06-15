TEMPLATE = subdirs

DISTFILES += \
        main.qml \
        qmldir \
        widgets/Widget.qml \
        widgets/FPS.qml \
        widgets/Clock.qml \
        widgets/ItemCount.qml \
        widgets/Resolution.qml \
        widgets/InfoTray.qml \
        common/VisualEffect.qml \
        common/ArtImage.qml \
        common/View.qml \
        physics/BoxBody.qml \
        physics/ImageBoxBody.qml \
        physics/ArtBoxBody.qml \
        physics/RectangleBoxBody.qml \
        views/well/WellDelegate.qml \
        views/well/Well.qml \
        views/cascade/Cascade.qml \
        views/cascade/CascadeDelegate.qml \
        views/conveyor/Conveyor.qml \
        views/conveyor/Monty_python_foot.png \
        views/basic/Basic.qml \
        views/reel/Reel.qml \
        views/reel/ReelImage.qml \
        views/procession/Procession.qml \
        views/procession/ProcessionImage.qml \
        views/simplelistview/SimpleListView.qml \
        unlicensed/Unlicensed.qml \
        unlicensed/unlicensed.png \
        3rdparty/effects/Effects.qml \
        3rdparty/effects/Effect.qml \
        3rdparty/effects/Billboard.qml \
        3rdparty/effects/Emboss.qml \
        3rdparty/effects/GaussianBlur.qml \
        3rdparty/backdrops/qml-presentation-visuals/Swirl.qml \
        3rdparty/backdrops/qml-presentation-visuals/BackgroundSwirls.qml \
        3rdparty/backdrops/qml-presentation-visuals/particle.png \
        3rdparty/backdrops/cells/cells.qml \
        3rdparty/backdrops/cells/noise.png \
        3rdparty/effects/shaders/billboard.fsh \
        3rdparty/effects/shaders/emboss.fsh \
        3rdparty/effects/shaders/gaussianblur_h.fsh \
        3rdparty/effects/shaders/gaussianblur_v.fsh

qml.path = /usr/share/artriculate/qml
qml.files = *

INSTALLS += qml
