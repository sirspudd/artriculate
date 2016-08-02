#include "picturemodel.h"

#include <QDir>
#include <QDebug>
#include <QCoreApplication>

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


PictureModel::PictureModel(QObject *parent)
    : QAbstractListModel(parent)
{ /**/ }

PictureModel::~PictureModel()
{
    // TODO: Destroy model
}

void PictureModel::addModelNode(const FSNode* parentNode)
{
    QCoreApplication::processEvents();

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

void PictureModel::setModelRoot(const QString &root)
{
    QDir currentDir(root);
    if (!currentDir.exists()) {
        qDebug() << "Being told to watch a non existent directory";
    }
    addModelNode(new FSNode(root));
}

void PictureModel::setSupportedExtensions(QStringList extensions) {
    this->extensions = extensions;
}

int PictureModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return files.length();
}

QUrl PictureModel::randomPicture() const
{
    if (files.size() <= 0)
        return QString("qrc:///qt_logo_green_rgb.png");

    return QUrl::fromLocalFile(FSNode::qualifyNode(files.at(qrand()%files.size())));
}

QVariant PictureModel::data(const QModelIndex &index, int role) const
{
    Q_UNUSED(role)
    if (index.row() < 0 || index.row() >= files.length())
        return QVariant();

    const FSNode *node = files.at(index.row());

    return FSNode::qualifyNode(node);
}

void PictureModel::addSupportedExtension(const QString &extension)
{
    extensions << extension;
}

QHash<int, QByteArray> PictureModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[PathRole] = "path";
    return roles;
}
