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
