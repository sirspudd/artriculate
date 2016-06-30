#include "picturemodel.h"

#include <ftw.h>
#include <stdio.h>

#include <QDir>

#include <QDebug>

PictureModel* PictureModel::model = 0;

int handleDirNode(const char *fpath, const struct stat *sb, int type, struct FTW *ftwbuf) {
    if (type == FTW_F) {
      PictureModel::instance()->addPath(fpath);
    }
    return 0;
}

PictureModel::PictureModel(QObject *parent)
{ /**/ }

PictureModel *PictureModel::instance()
{
    if (!model) {
        model = new PictureModel();
    }
    return model;
}

bool PictureModel::setModelRoot(const QString &root)
{
    qDebug() << "Flattening" << root;

    QDir currentDir(root);
    if (!currentDir.exists()) {
        qDebug() << "Being told to watch a non existent directory";
        return false;
    }

//    QString dirName = currentDir.dirName();
//    qDebug() << dirName;
//    currentDir.cdUp();
//    QDir::setCurrent(currentDir.path());

    nftw(root.toLatin1().data(), handleDirNode, 1000, FTW_PHYS);
    qDebug() << "Finished flattening";
    return true;
}

int PictureModel::rowCount(const QModelIndex &parent) const
{
    return paths.length();
}

QString PictureModel::randomPicture() const
{
    return paths.at(qrand()%paths.size());
}

QVariant PictureModel::data(const QModelIndex &index, int role) const
{
    if (index.row() < 0 || index.row() >= paths.length())
        return QVariant();

    return paths.at(index.row());
}

bool PictureModel::addPath(const QString &path)
{
    if (!extensions.isEmpty()) {
        QString extension = path.mid(path.length() - 3);
        if (!extensions.contains(extension))
            return false;
    }
    paths << path;
    return true;
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
