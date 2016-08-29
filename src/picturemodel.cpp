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

#include <QDir>
#include <QDebug>
#include <QCoreApplication>
#include <QSettings>
#include <QThread>
#include <QImageReader>
#include <QMimeDatabase>

struct FSNode {
  FSNode(const QString& rname, const FSNode *pparent = nullptr);

  static QString qualifyNode(const FSNode *node);

  const QString name;
  const FSNode *parent;

  QSize size;
  qreal ratio;
};

FSNode::FSNode(const QString& rname, const FSNode *pparent)
    : name(rname),
      parent(pparent)
{
}

QString FSNode::qualifyNode(const FSNode *node) {
    QString qualifiedPath;

    while(node->parent != nullptr) {
        qualifiedPath = "/" + node->name + qualifiedPath;
        node = node->parent;
    }
    qualifiedPath = node->name + qualifiedPath;

    return qualifiedPath;
}

class FSNodeTree : public QObject
{
    Q_OBJECT
public:
    FSNodeTree(PictureModel *p);

    void addModelNode(const FSNode* parentNode);
    void setModelRoot(const QString& rootDir) { this->rootDir = rootDir; }

    int fileCount() const { return files.length(); }
    QList<FSNode*> files;
public slots:
    void populate();
signals:
    void countChanged();
private:
    QStringList extensions;
    QString rootDir;
};

FSNodeTree::FSNodeTree(PictureModel *p)
    : QObject(nullptr)
{
    connect(this, SIGNAL(countChanged()), p, SIGNAL(countChanged()));

    QMimeDatabase mimeDatabase;
    for(const QByteArray &m: QImageReader::supportedMimeTypes()) {
        for(const QString &suffix: mimeDatabase.mimeTypeForName(m).suffixes())
            extensions.append(suffix);
    }

    if (extensions.isEmpty()) {
        qFatal("Your Qt install has no image format support");
    }
}

void FSNodeTree::addModelNode(const FSNode* parentNode)
{
    // TODO: Check for symlink recursion
    QDir parentDir(FSNode::qualifyNode(parentNode));

    for(const QString &currentDir : parentDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot)) {
        const FSNode *dir = new FSNode(currentDir, parentNode);
        addModelNode(dir);
    }

    for(const QString &currentFile : parentDir.entryList(QDir::Files)) {
        QString extension = currentFile.mid(currentFile.length() - 3);
        if (!extensions.contains(extension))
            continue;

        FSNode *file = new FSNode(currentFile, parentNode);
        const QString fullPath = FSNode::qualifyNode(file);

        QSize size = QImageReader(fullPath).size();

        bool rational = false;
        if (size.isValid()) {
            file->size = size;
            qreal ratio = qreal(size.width())/size.height();
            if ((ratio < 0.01) || (ratio > 100)) {
                qDebug() << "Image" << fullPath << "has excessive ratio" << ratio << "excluded";
            } else {
                rational = true;
                file->ratio = ratio;
            }
        } else {
            qDebug() << "Discarding" << fullPath << "due to invalid size";
        }

        if (rational) {
            files << file;
            emit countChanged();
        }  else {
            delete file;
        }
    }
}

void FSNodeTree::populate()
{
    QDir currentDir(rootDir);
    if (!currentDir.exists()) {
        qDebug() << "Being told to watch a non existent directory";
    }
    addModelNode(new FSNode(rootDir));
}

class PictureModel::PictureModelPrivate {
public:
    PictureModelPrivate(PictureModel* p);
    ~PictureModelPrivate();

    FSNodeTree *fsTree;
private:
    QThread scanningThread;
};

PictureModel::PictureModelPrivate::PictureModelPrivate(PictureModel* p)
{
    QSettings settings;
    QString artPath = settings.value("artPath","/blackhole/media/art").toString();

    settings.setValue("artPath", artPath);

    fsTree = new FSNodeTree(p);

    fsTree->setModelRoot(artPath);

    fsTree->moveToThread(&scanningThread);
    scanningThread.start();

    QMetaObject::invokeMethod(fsTree, "populate", Qt::QueuedConnection);
};

PictureModel::PictureModelPrivate::~PictureModelPrivate()
{
    scanningThread.quit();
    scanningThread.wait(5000);

    delete fsTree;
    fsTree = nullptr;
};

PictureModel::PictureModel(QObject *parent)
    : QAbstractListModel(parent),
      d(new PictureModelPrivate(this)) { /**/ }

PictureModel::~PictureModel()
{
    delete d;
    d = nullptr;
}

int PictureModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return d->fsTree->fileCount();
}

QVariant PictureModel::data(const QModelIndex &index, int role) const
{
    if (index.row() < 0 || index.row() >= d->fsTree->fileCount()) {
        switch (role) {
        case SizeRole:
            return QSize(1222,900);
        case RatioRole:
            return 1222/900;
        case NameRole:
            return "Qt logo";
        case PathRole:
        default:
            return QString("qrc:///qt_logo_green_rgb.png");
        }
    }


    switch (role) {
    case SizeRole:
        return d->fsTree->files.at(index.row())->size;
    case RatioRole:
        return d->fsTree->files.at(index.row())->ratio;
    case NameRole:
        return d->fsTree->files.at(index.row())->name;
    case PathRole:
    default:
        return QUrl::fromLocalFile(FSNode::qualifyNode(d->fsTree->files.at(index.row())));
    }

    return QVariant();
}

QHash<int, QByteArray> PictureModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[NameRole] = "name";
    roles[PathRole] = "path";
    roles[SizeRole] = "size";
    roles[RatioRole] = "ratio";
    return roles;
}

#include "picturemodel.moc"
