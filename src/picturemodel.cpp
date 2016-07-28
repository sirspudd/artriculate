#include "picturemodel.h"

#include <QDir>
#include <QDebug>
#include <QCoreApplication>

struct FSNode {
  FSNode(const QString& rname, const FSNode *pparent = nullptr)
      : name(rname),
        parent(pparent) { /**/ }

  const QString name;
  const FSNode *parent;
};

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
    QDir parentDir(qualifyNode(parentNode));

    foreach(const QString &currentDir, parentDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot)) {
        const FSNode *dir = new FSNode(currentDir, parentNode);
        addModelNode(dir);
    }

    foreach(const QString &currentFile, parentDir.entryList(QDir::Files)) {
        if (!extensions.isEmpty()) {
            QString extension = currentFile.mid(currentFile.length() - 3);
            if (!extensions.contains(extension))
                continue;
        }
        const FSNode *file = new FSNode(currentFile, parentNode);
        files << file;
    }
}

void PictureModel::setModelRoot(const QString &root)
{
    QDir currentDir(root);
    if (!currentDir.exists()) {
        qDebug() << "Being told to watch a non existent directory";
    }
    addModelNode(new FSNode(root));

//    foreach(FSNode *node, files) {
//        qDebug() << "Contains:" << qualifyNode(node);
//    }
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

    return QUrl::fromLocalFile(qualifyNode(files.at(qrand()%files.size())));
}

QVariant PictureModel::data(const QModelIndex &index, int role) const
{
    Q_UNUSED(role)
    if (index.row() < 0 || index.row() >= files.length())
        return QVariant();

    const FSNode *node = files.at(index.row());

    return qualifyNode(node);
}

QString PictureModel::qualifyNode(const FSNode *node) const {
    QString qualifiedPath;

    while(node->parent != nullptr) {
        qualifiedPath = "/" + node->name + qualifiedPath;
        node = node->parent;
    }
    qualifiedPath = node->name + qualifiedPath;

    return qualifiedPath;
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
