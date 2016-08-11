#include "picturemodel.h"

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QSettings>
#include <QSurfaceFormat>
#include <QTimer>

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QTextStream>

#include <QDebug>

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
    PictureModel model;

    engine.rootContext()->setContextProperty("imageModel", &model);
    engine.rootContext()->setContextProperty("fileReader", new FileReader(&app));
    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));

    return app.exec();
}

#include "main.moc"
