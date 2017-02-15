#ifndef FILEREADER_H
#define FILEREADER_H

#include <QObject>
#include <QFile>
#include <QTextStream>

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

#endif // FILEREADER_H
