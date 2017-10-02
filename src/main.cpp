/****************************************************************************
** Artriculate: Art comes tumbling down
** Copyright (C) 2016 Chaos Reins
**
** This program is free software: you can redistribute it and/or modify
** it under the terms of the GNU General Public License as published by
** the Free Software Foundation, either version 3 of the License, or
** (at your option) any later version.
**
** This program is distributed in the hope that it will be useful,
** but WITHOUT ANY WARRANTY; without even the implied warranty of
** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
** GNU General Public License for more details.
**
** You should have received a copy of the GNU General Public License
** along with this program.  If not, see <http://www.gnu.org/licenses/>.
****************************************************************************/

#include "picturemodel.h"

#ifdef USING_SYSTEMD
#include <systemd/sd-daemon.h>
#endif

#include <QFontDatabase>
#include <QGuiApplication>
#include <QQuickView>
#include <QQmlContext>
#include <QQmlEngine>
#include <QSettings>
#include <QSurfaceFormat>
#include <QTimer>
#include <QQuickWindow>
#include <QDir>
#include <QFileInfo>
#include <QTextStream>
#include <QDebug>
#include <QScreen>
#include <QDBusInterface>
#include <QDBusConnection>
#include <QFileSystemWatcher>
#include <QtPlugin>
#include <QMetaObject>

class CloseEventFilter : public QObject
{
    Q_OBJECT
public:
    CloseEventFilter(QObject *p) : QObject(p) { /**/ }

protected:
    bool eventFilter(QObject *obj, QEvent *event);
};

bool CloseEventFilter::eventFilter(QObject *obj, QEvent *event)
{
    if (event->type() == QEvent::Close) {
        qApp->quit();
    }

    return QObject::eventFilter(obj, event);
}

class NativeUtils : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool rebootRequired MEMBER rebootRequired NOTIFY rebootRequiredChanged)
public:
    NativeUtils(QObject *p);

signals:
    void rebootRequiredChanged();
public slots:
    void monitorRunPath(const QString &path);
private:
    QString watchFile;
    QFileSystemWatcher runDirWatcher;
    bool rebootRequired;
};

NativeUtils::NativeUtils(QObject *p)
    : QObject(p),
      watchFile("/run/reboot-required"),
      rebootRequired(false)
{
    runDirWatcher.addPath(QFileInfo(watchFile).absolutePath());
    connect(&runDirWatcher, &QFileSystemWatcher::directoryChanged, this, &NativeUtils::monitorRunPath);
    monitorRunPath("");
}

void NativeUtils::monitorRunPath(const QString &path)
{
    Q_UNUSED(path);

    rebootRequired = QFileInfo::exists(watchFile);
    emit rebootRequiredChanged();
}

class ArtView {
public:
    static void populateScreen(QScreen *screen = nullptr);
private:
    static QQmlEngine* sharedQmlEngine;
};

QQmlEngine* ArtView::sharedQmlEngine = nullptr;

void ArtView::populateScreen(QScreen *screen)
{
    static QString qmlPath;
#ifdef COMPILED_RESOURCES
    qmlPath = "qrc:/qml";
#else
    qmlPath = QCoreApplication::applicationDirPath() % "/qml";
    if (!QDir(qmlPath).exists()) {
        qmlPath = "/usr/share/" % qApp->applicationName() % "/qml";
    }
#endif

    QQuickView *view;
    if (sharedQmlEngine) {
        view = new QQuickView(sharedQmlEngine, nullptr);
    } else {
        view = new QQuickView();
        sharedQmlEngine = view->engine();
        sharedQmlEngine->addImportPath(qmlPath);
        sharedQmlEngine->rootContext()->setContextProperty("nativeUtils", new NativeUtils(sharedQmlEngine));
        sharedQmlEngine->rootContext()->setContextProperty("imageModel", new PictureModel(sharedQmlEngine));
        QObject::connect(sharedQmlEngine, &QQmlEngine::quit, qApp, &QCoreApplication::quit);
    }
    if (screen) {
        view->setScreen(screen);
    } else {
        screen = view->screen();
    }
    QRect geometry = screen->availableGeometry();
    view->setColor(Qt::transparent);
    view->setResizeMode(QQuickView::SizeRootObjectToView);
    view->setSource(QUrl(qmlPath + "/main.qml"));
    view->setGeometry(geometry);
    view->showFullScreen();

    QObject::connect(view, &QQuickView::statusChanged, [](QQuickView::Status status) {
        if (status == QQuickView::Error) {
            QMetaObject::invokeMethod(qApp, "quit", Qt::QueuedConnection);
        }
    });

    qDebug() << "Displaying artwork on" << screen << "with geometry" << geometry;
}

int main(int argc, char *argv[])
{
#ifdef STATIC_BUILD
    Q_IMPORT_PLUGIN(QmlSettingsPlugin)
    Q_IMPORT_PLUGIN(QtQuick2WindowPlugin)
    Q_IMPORT_PLUGIN(QtQuick2Plugin)
#endif
    qsrand(time(NULL));

    QGuiApplication app(argc, argv);
    if (QFontDatabase::addApplicationFont(":/Lato-Regular.ttf") == -1) {
        qDebug() << "Failed to successfully add the application font";
    }
    app.setFont(QFont("Lato Regular"));
    app.setOrganizationName("Chaos Reins");
    app.setApplicationName("artriculate");
    app.installEventFilter(new CloseEventFilter(&app));

    QSettings settings;

    if (settings.value("raster", false).toBool()) {
#if QT_VERSION < QT_VERSION_CHECK(5, 8, 0)
        qDebug() << "Trying to use the SG software backend prior to Qt 5.8";
#else
        QQuickWindow::setSceneGraphBackend(QSGRendererInterface::Software);
#endif
    } else {
        if (settings.value("force32bpp", true).toBool()) {
            QSurfaceFormat format = QSurfaceFormat::defaultFormat();
            format.setAlphaBufferSize(0);
            format.setRedBufferSize(8);
            format.setGreenBufferSize(8);
            format.setBlueBufferSize(8);
            QSurfaceFormat::setDefaultFormat(format);
        }

        if (settings.value("forceSingleBuffer", false).toBool()) {
            QSurfaceFormat format = QSurfaceFormat::defaultFormat();
            format.setSwapBehavior(QSurfaceFormat::SingleBuffer);
            QSurfaceFormat::setDefaultFormat(format);
        } else if (settings.value("forceDoubleBuffer", false).toBool()) {
            QSurfaceFormat format = QSurfaceFormat::defaultFormat();
            format.setSwapBehavior(QSurfaceFormat::TripleBuffer);
            QSurfaceFormat::setDefaultFormat(format);
        }
    }

    // qdbus org.freedesktop.ScreenSaver /org/freedesktop/ScreenSaver Inhibit "artriculate" "media playback"

    if (settings.value("suppressScreensaver", false).toBool()) {
        QDBusInterface screenSaver("org.freedesktop.ScreenSaver", "/org/freedesktop/ScreenSaver");
        uint id = screenSaver.call("Inhibit", app.applicationName(), "Media playback").arguments().at(0).toInt();
        QObject::connect(&app, &QCoreApplication::aboutToQuit, [id]() {
            QDBusInterface screenSaver("org.freedesktop.ScreenSaver", "/org/freedesktop/ScreenSaver");
            screenSaver.call("UnInhibit", id);
        });
    }

    qmlRegisterType<PictureModel>("PictureModel", 1, 0, "PictureModel");

    int screenIndex = settings.value("screenIndex", -2).toInt();
    QList<QScreen*> screens = QGuiApplication::screens();

    if (screenIndex == -2) {
        ArtView::populateScreen();
    } else if (screenIndex == -1) {
        foreach(QScreen *screen, screens) {
            ArtView::populateScreen(screen);
        }
    } else {
        if ((screenIndex >= 0) && (screenIndex < screens.length())) {
            ArtView::populateScreen(screens.at(screenIndex));
        } else {
            ArtView::populateScreen();
        }
    }
    settings.setValue("screenIndex", screenIndex);

    QGuiApplication::processEvents();
#ifdef USING_SYSTEMD
    sd_notify(0, "READY=1");
#endif
    return app.exec();
}

#include "main.moc"
