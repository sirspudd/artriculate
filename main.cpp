#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QThread>
#include <QSettings>
#include <QSurfaceFormat>
#include <QTimer>

#include <picturemodel.h>

int main(int argc, char *argv[])
{
    qsrand(time(NULL));

    QGuiApplication app(argc, argv);

    app.setOrganizationName("Chaos Reins");
    app.setApplicationName("Articulate");

    QSettings settings;

    if (settings.value("force32bpp", false).toBool()) {
        QSurfaceFormat format = QSurfaceFormat::defaultFormat();
        format.setAlphaBufferSize(8);
        format.setRedBufferSize(8);
        format.setGreenBufferSize(8);
        format.setBlueBufferSize(8);
        if (settings.value("forceSingleBuffer", false).toBool())
          format.setSwapBehavior(QSurfaceFormat::SingleBuffer);
        QSurfaceFormat::setDefaultFormat(format);
    }

    QQmlApplicationEngine engine;
    QThread scanningThread;
    PictureModel *model = new PictureModel();
    const QString &artPath = settings.value("artPath","/blackhole/media/art").toString();

    model->addSupportedExtension("jpg");
    model->addSupportedExtension("png");
    model->moveToThread(&scanningThread);
    scanningThread.start();
    //QTimer::singleShot(0, model, [model,artPath]() { model->setModelRoot(artPath); });
    QMetaObject::invokeMethod(model, "setModelRoot", Qt::QueuedConnection, Q_ARG(QString,artPath));
    settings.setValue("artPath", artPath);

    engine.rootContext()->setContextProperty("imageModel", model);
    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));

    QObject::connect(&app, &QGuiApplication::lastWindowClosed, &scanningThread, &QThread::quit);

    return app.exec();
}
