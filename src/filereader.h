#ifndef FILEREADER_H
#define FILEREADER_H

#include <QObject>
#include <QFile>
#include <QTextStream>

#include <QCoreApplication>

class FileReader : public QObject {
    Q_OBJECT
public:
    FileReader(QObject *p) : QObject(p) { /**/ }
    Q_INVOKABLE static QString readFile(const QString &fileName)
    {
        QString content;
        QString qmlPath = QCoreApplication::applicationDirPath() + "/../qml/3rdparty/effects/";
        QFile file(qmlPath + fileName);
        if (file.open(QIODevice::ReadOnly)) {
            QTextStream stream(&file);
            content = stream.readAll();
        }
        return content;
    }
};

#endif // FILEREADER_H
