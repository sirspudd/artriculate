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
#include "filereader.h"
#include "helperfunctions.h"

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
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

int main(int argc, char *argv[])
{
    qsrand(time(NULL));

    QGuiApplication app(argc, argv);

    app.setOrganizationName("Chaos Reins");
    app.setApplicationName("Articulate");

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

    QQmlApplicationEngine engine;
    qmlRegisterType<PictureModel>("PictureModel", 1, 0, "PictureModel");

    engine.addImportPath("qrc:/");
    engine.rootContext()->setContextProperty("screenSize", app.screens().at(0)->availableSize());
    engine.rootContext()->setContextProperty("fileReader", new FileReader(&app));
    engine.rootContext()->setContextProperty("nativeHelper", new HelperFunctions(&app));
    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));

    return app.exec();
}
