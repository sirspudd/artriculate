#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QThread>

#include <picturemodel.h>

class PictureThreadWrapper : public QObject {
public:
    PictureThreadWrapper(QObject *parent = 0) : QObject (parent) {
        PictureModel::instance()->addSupportedExtension("jpg");
        PictureModel::instance()->setModelRoot("/blackhole/media/art");
    }
};

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;

    QThread scanningThread;
    PictureThreadWrapper *wrapper = new PictureThreadWrapper();
    wrapper->moveToThread(&scanningThread);
    scanningThread.start();

    engine.rootContext()->setContextProperty("imageModel", PictureModel::instance());

    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));

    return app.exec();
}
