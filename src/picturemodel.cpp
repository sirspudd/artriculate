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
#include <QElapsedTimer>
#include <QStandardPaths>

#include <QtSql/QSqlDatabase>
#include <QtSql/QSqlError>
#include <QtSql/QSqlQuery>
#include <QtSql/QSqlDriver>

namespace {
    QSqlDatabase openDBConnection(const QString &connectionName) {
        QSqlDatabase db = QSqlDatabase::addDatabase("QSQLITE", connectionName);
        QFileInfo dbFile(QStandardPaths::standardLocations(QStandardPaths::DataLocation).first() + "/" + qApp->applicationName() + ".db");
        QDir().mkpath(dbFile.absolutePath());
        db.setDatabaseName(dbFile.absoluteFilePath());

        if (!db.open()) {
            qDebug() << "Failed to open the database:" << dbFile.absoluteFilePath();
            qDebug() << "Error:" << db.lastError().text();
            qApp->exit(-1);
        }

        return db;
}
    QString stripDbHostileCharacters(QString path) {
        return path.replace(QString("/"), QString(""));
    }

    inline int offsetHash(int hash) { return hash + 1; }
}

struct ArtPiece {
    ArtPiece() : refCount(0) { /**/ }
    QString path;
    QSize size;
    int refCount;
};

struct FSNode {
  FSNode(const QString& rname, const FSNode *pparent = nullptr);

  static QString qualifyNode(const FSNode *node);

  const QString name;
  const FSNode *parent;
};

struct FSLeafNode : public FSNode {
    using FSNode::FSNode;
    QSize size;
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
    FSNodeTree(const QString& path);
    virtual ~FSNodeTree();

    void addModelNode(const FSNode* parentNode);

    int fileCount() const { return files.length(); }
    QVector<FSLeafNode*> files;
public slots:
    void populate(bool useDatabaseBackend);
signals:
    void countChanged();
private:
    void dumpTreeToDb();

    QStringList extensions;
    QString rootDir;
};

FSNodeTree::FSNodeTree(const QString& path)
    : QObject(nullptr),
      rootDir(path)
{
    QMimeDatabase mimeDatabase;
    foreach(const QByteArray &m, QImageReader::supportedMimeTypes()) {
        foreach(const QString &suffix, mimeDatabase.mimeTypeForName(m).suffixes())
            extensions.append(suffix);
    }

    if (extensions.isEmpty()) {
        qFatal("Your Qt install has no image format support");
    }
}

FSNodeTree::~FSNodeTree()
{
    QSet<const FSNode*> nodes;
    foreach(const FSNode *node, files) {
        while(node) {
            nodes << node;
            node = node->parent;
        }
    }
    qDeleteAll(nodes.toList());
}

void FSNodeTree::addModelNode(const FSNode* parentNode)
{
    // TODO: Check for symlink recursion
    QDir parentDir(FSNode::qualifyNode(parentNode));

    foreach(const QString &currentDir, parentDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot)) {
        const FSNode *dir = new FSNode(currentDir, parentNode);
        addModelNode(dir);
    }

    foreach(const QString &currentFile, parentDir.entryList(QDir::Files)) {
        QString extension = currentFile.mid(currentFile.length() - 3);
        if (!extensions.contains(extension))
            continue;

        FSLeafNode *file = new FSLeafNode(currentFile, parentNode);
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

void FSNodeTree::populate(bool useDatabaseBackend)
{
    QElapsedTimer timer;
    timer.start();
    QDir currentDir(rootDir);
    if (!currentDir.exists()) {
        qDebug() << "Being told to watch a non existent directory:" << rootDir;
    }
    addModelNode(new FSNode(rootDir));
    qDebug() << "Completed building file tree containing:" << files.length() << "images after:" << timer.elapsed() << "ms";

    if (useDatabaseBackend) {
        qDebug() << "No database found; dumping tree to db" << rootDir;
        timer.restart();
        dumpTreeToDb();
        qDebug() << "Completed database dump after:" << timer.elapsed() << "ms";
    }
}

void FSNodeTree::dumpTreeToDb()
{
    QSqlDatabase db = openDBConnection("write");

    QSqlQuery q("", db);
    if (!q.exec(QString("create table %1 (path varchar, width integer, height integer)").arg(::stripDbHostileCharacters(rootDir)))) {
        qDebug() << "Failed to init DB with:" << q.lastError().text();
        return;
    }

    qDebug() << "Database supports transactions" << QSqlDatabase::database().driver()->hasFeature(QSqlDriver::Transactions);

    // Turns out SQLITE has a 999 variable limit by default
    // Arch shieleded me from this

    int varLimitPerWave = 999;
    int varCountPerItem = 3;
    int itemCountPerWave = varLimitPerWave/varCountPerItem;

    int waveCount = files.length()/itemCountPerWave;
    const int waveTail = files.length()%itemCountPerWave;

    if (waveTail > 0) {
        waveCount += 1;
    }

    qDebug() << "About to drop" << files.length() << "files to DB";
    qDebug() << "This will require" << waveCount << "separate DB transactions";

    for (int wave = 0; wave < waveCount; wave++)
    {
        int itemCount = itemCountPerWave;
        if ((waveTail > 0) && (wave == waveCount - 1)) {
            itemCount = waveTail;
        }

        QString insertQuery = QString("INSERT INTO %1 (path, width, height) VALUES ").arg(::stripDbHostileCharacters(rootDir));
        QString insertQueryValues("(?, ?, ?),");

        insertQuery.reserve(insertQuery.size() + insertQueryValues.size()*itemCount);
        for(int i = 0; i < itemCount; i++) {
            insertQuery.append(insertQueryValues);
        }

        insertQuery = insertQuery.replace(insertQuery.length()-1, 1, ";");

        db.transaction();
        QSqlQuery query("", db);

        if (!query.prepare(insertQuery)) {
            qDebug() << "Query preperation failed with" << query.lastError().text();
            return;
        }

        for(int i = wave*itemCountPerWave; i < (wave*itemCountPerWave + itemCount); i++) {
            const FSLeafNode *node = files.at(i);
            query.addBindValue(node->qualifyNode(node));
            query.addBindValue(node->size.width());
            query.addBindValue(node->size.height());
        }

        query.exec();

        if (db.commit()) {
            qDebug() << "SQL transaction succeeded";
        } else {
            qDebug() << "SQL transaction failed";
        }

        QSqlError err = query.lastError();
        if (err.type() != QSqlError::NoError) {
            qDebug() << "Database dump of content tree failed with" << err.text();
        } else {
            qDebug() << "Successfully finished adding wave" << wave << "to DB" << rootDir;
        }
    }
}

class PictureModel::PictureModelPrivate {
public:
    PictureModelPrivate(PictureModel* p);
    ~PictureModelPrivate();

    FSNodeTree *fsTree;
    bool useDatabaseBackend;

    void cacheIndex(int index);
    void retireCachedIndex(int index);
    int itemCount();

    QHash<int, ArtPiece*> artwork;
private:
    PictureModel *parent;
    int collectionSize;
    QString artPath;
    void createFSTree(const QString &path);
    QThread scanningThread;
};

PictureModel::PictureModelPrivate::PictureModelPrivate(PictureModel* p)
    : fsTree(nullptr),
      parent(p)
{
    QSettings settings;
    useDatabaseBackend = settings.value("useDatabaseBackend", true).toBool();
    settings.setValue("useDatabaseBackend", useDatabaseBackend);

    artPath = settings.value("artPath", QStandardPaths::standardLocations(QStandardPaths::PicturesLocation).first()).toString();
    settings.setValue("artPath", artPath);

    if (useDatabaseBackend) {
        QSqlDatabase db = openDBConnection("read");

        QStringList tables = db.tables();
        if (tables.contains(::stripDbHostileCharacters(artPath), Qt::CaseInsensitive)) {
            QString queryString = "SELECT COUNT(*) FROM " % ::stripDbHostileCharacters(artPath) % ";";
            QSqlQuery query(queryString, db);
            query.next();

            collectionSize = query.value(0).toInt();
            QMetaObject::invokeMethod(parent, "countChanged");
            qDebug() << "Using existing database entry for" << artPath;
        } else {
            qDebug() << "No database found; creating file tree" << artPath;
            createFSTree(artPath);
        }
    } else {
        createFSTree(artPath);
    }
};

void PictureModel::PictureModelPrivate::createFSTree(const QString &path)
{
    fsTree = new FSNodeTree(path);
    connect(fsTree, &FSNodeTree::countChanged, parent, &PictureModel::countChanged);
    fsTree->moveToThread(&scanningThread);
    scanningThread.start();
    QMetaObject::invokeMethod(fsTree, "populate", Qt::QueuedConnection, Q_ARG(bool, useDatabaseBackend));
}

PictureModel::PictureModelPrivate::~PictureModelPrivate()
{
    if (fsTree) {
        scanningThread.quit();
        scanningThread.wait(5000);

        delete fsTree;
        fsTree = nullptr;
    }
}

int PictureModel::PictureModelPrivate::itemCount() {
    return fsTree ? fsTree->fileCount() : collectionSize;
};

void PictureModel::PictureModelPrivate::cacheIndex(int index)
{
    int hashIndex = ::offsetHash(index);

    if (artwork.contains(hashIndex)) {
        artwork[hashIndex]->refCount++;
        return;
    }

    QString queryString = "SELECT path, width, height FROM " % ::stripDbHostileCharacters(artPath) % " LIMIT 1 OFFSET " % QString::number(index) % ";";

    QSqlDatabase db = QSqlDatabase::database("read", true);
    QSqlQuery query(queryString, db);

    query.next();

    ArtPiece *art = new ArtPiece;
    art->path = query.value(0).toString();
    art->size = QSize(query.value(1).toInt(), query.value(2).toInt());
    art->refCount++;

    artwork[hashIndex] = art;
}

void PictureModel::PictureModelPrivate::retireCachedIndex(int index)
{
    int hashIndex = ::offsetHash(index);
    artwork[hashIndex]->refCount--;
    if (artwork[hashIndex]->refCount < 1) {
        delete artwork[hashIndex];
        artwork.remove(hashIndex);
    }
}

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
    return d->itemCount();
}

QVariant PictureModel::data(const QModelIndex &index, int role) const
{
    // What the fuck; Qt queries item 0 before we substantiate it
    // I get to offset my hash by 1 or loss a piece of art
    if (index.row() <= 0 || index.row() >= d->itemCount()) {
        switch (role) {
        case SizeRole:
            return QSize(1222,900);
        case NameRole:
            return "Qt logo";
        case PathRole:
        default:
            return QString("qrc:///qt_logo_green_rgb.png");
        }
    }

    if (d->fsTree) {
        switch (role) {
        case SizeRole:
            return d->fsTree->files.at(index.row())->size;
        case NameRole:
            return d->fsTree->files.at(index.row())->name;
        case PathRole:
        default:
            return QUrl::fromLocalFile(FSNode::qualifyNode(d->fsTree->files.at(index.row())));
        }
    } else {
        int hashIndex = ::offsetHash(index.row());
        switch (role) {
        case SizeRole: {
            return d->artwork[hashIndex]->size;
        }
        case NameRole:
            return d->artwork[hashIndex]->path;
        case PathRole:
        default:
            return QUrl::fromLocalFile(d->artwork[hashIndex]->path);
        }
    }

    return QVariant();
}

int PictureModel::requestIndex()
{
    int index = d->itemCount() == 0 ? 0 : qrand() % d->itemCount();

    if (!d->fsTree) {
        d->cacheIndex(index);
    }

    return index;
}

void PictureModel::retireIndex(int index)
{
    if (!d->fsTree) {
        d->retireCachedIndex(index);
    }
}

QHash<int, QByteArray> PictureModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[NameRole] = "name";
    roles[PathRole] = "path";
    roles[SizeRole] = "size";
    return roles;
}

#include "moc/picturemodel.moc"
