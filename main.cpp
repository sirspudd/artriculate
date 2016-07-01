#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QThread>
#include <QSettings>
#include <QSurfaceFormat>

#include <picturemodel.h>

class PictureThreadWrapper : public QObject {
public:
    PictureThreadWrapper(QObject *parent = 0) : QObject (parent) {
        QSettings settings;
        const QString &artPath = settings.value("artPath","/blackhole/media/art/Banksy").toString();
        PictureModel::instance()->addSupportedExtension("jpg");
        PictureModel::instance()->setModelRoot(artPath);
        settings.setValue("artPath", artPath);
    }
};

int main(int argc, char *argv[])
{
    qsrand(time(NULL));

    QSurfaceFormat format = QSurfaceFormat::defaultFormat();
    format.setAlphaBufferSize(8);
    format.setRedBufferSize(8);
    format.setGreenBufferSize(8);
    format.setBlueBufferSize(8);
    QSurfaceFormat::setDefaultFormat(format);

    QGuiApplication app(argc, argv);

    app.setOrganizationName("Chaos Reins");
    app.setApplicationName("Articulate");

    QQmlApplicationEngine engine;

    QThread scanningThread;
    PictureThreadWrapper *wrapper = new PictureThreadWrapper();
    wrapper->moveToThread(&scanningThread);
    scanningThread.start();

    engine.rootContext()->setContextProperty("imageModel", PictureModel::instance());

    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));

    return app.exec();
}
