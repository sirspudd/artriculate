#include "picturemodel.h"

#include <QDir>
#include <QDebug>
#include <QCoreApplication>
#include <QSettings>
#include <QThread>

struct FSNode {
  FSNode(const QString& rname, const FSNode *pparent = nullptr)
      : name(rname),
        parent(pparent) { /**/ }

  static QString qualifyNode(const FSNode *node);

  const QString name;
  const FSNode *parent;
};

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
    void setSupportedExtensions(const QStringList extensions) { this->extensions = extensions; }
    void setModelRoot(const QString& rootDir) { this->rootDir = rootDir; }

    int fileCount() const { return files.length(); }
    QUrl randomFileUrl() const;
public slots:
    void populate();
signals:
    void countChanged();
private:
    QList<const FSNode*> files;
    QStringList extensions;
    QString rootDir;
};

FSNodeTree::FSNodeTree(PictureModel *p)
    : QObject(nullptr)
{
    connect(this, SIGNAL(countChanged()), p, SIGNAL(countChanged()));
}


QUrl FSNodeTree::randomFileUrl() const {
    if (files.size() <= 0)
        return QString("qrc:///qt_logo_green_rgb.png");

    return QUrl::fromLocalFile(FSNode::qualifyNode(files.at(qrand()%files.size())));
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
        if (!extensions.isEmpty()) {
            QString extension = currentFile.mid(currentFile.length() - 3);
            if (!extensions.contains(extension))
                continue;
        }
        const FSNode *file = new FSNode(currentFile, parentNode);
        files << file;
        emit countChanged();
    }
}

void FSNodeTree::populate()
{
    QDir currentDir(rootDir);
    if (!currentDir.exists()) {
        qDebug() << "Being told to watch a non existent directory";
    }
    if (extensions.empty()) {
        qDebug() << "No supported extensions provided, defaulting to jpg and png";
        extensions << "jpg" << "png";
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
    QStringList extensions = settings.value("extensions", QStringList() << "jpg" << "png").toStringList();

    settings.setValue("artPath", artPath);
    settings.setValue("extensions", extensions);

    fsTree = new FSNodeTree(p);

    fsTree->setSupportedExtensions(extensions);
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

QUrl PictureModel::randomPicture() const
{   return d->fsTree->randomFileUrl();
}

QVariant PictureModel::data(const QModelIndex &index, int role) const
{
    Q_UNUSED(role)
    if (index.row() < 0 || index.row() >= d->fsTree->fileCount())
        return QVariant();

    return d->fsTree->randomFileUrl();
}

QHash<int, QByteArray> PictureModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[PathRole] = "path";
    return roles;
}

#include "picturemodel.moc"
