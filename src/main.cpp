#include "picturemodel.h"

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QThread>
#include <QSettings>
#include <QSurfaceFormat>
#include <QTimer>

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QTextStream>

#include <QDebug>
#include <QAbstractItemModel>

class ModelRelay : public QObject {
    Q_OBJECT
signals:
    void countChanged();
};

class FileReader : public QObject {
    Q_OBJECT
public:
    FileReader(QObject *p) : QObject(p) { /**/ }
    Q_INVOKABLE static QString readFile(const QString &fileName)
    {
        QString content;
        QFile file(fileName);
        if (file.open(QIODevice::ReadOnly)) {
            QTextStream stream(&file);
            content = stream.readAll();
        }
        return content;
    }
};

int main(int argc, char *argv[])
{
    qsrand(time(NULL));

    QGuiApplication app(argc, argv);

    app.setOrganizationName("Chaos Reins");
    app.setApplicationName("Articulate");

    QSettings settings;

    if (settings.value("force32bpp", true).toBool()) {
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
    QString artPath = settings.value("artPath","/blackhole/media/art").toString();
    QStringList extensions = settings.value("extensions", QStringList() << "jpg" << "png").toStringList();
    settings.setValue("artPath", artPath);
    settings.setValue("extensions", extensions);

    model->setSupportedExtensions(extensions);
    model->moveToThread(&scanningThread);
    scanningThread.start();
    QMetaObject::invokeMethod(model, "setModelRoot", Qt::QueuedConnection, Q_ARG(QString,artPath));

    ModelRelay modelRelay;
    QObject::connect(model, &PictureModel::countChanged, &modelRelay, &ModelRelay::countChanged, Qt::QueuedConnection);

    engine.rootContext()->setContextProperty("imageModel", model);
    engine.rootContext()->setContextProperty("modelRelay", &modelRelay);

    engine.rootContext()->setContextProperty("fileReader", new FileReader(&app));
    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));

    QObject::connect(&app, &QGuiApplication::lastWindowClosed, &scanningThread, &QThread::quit);

    return app.exec();
}

#include "main.moc"
