#ifndef PICTUREMODEL_H
#define PICTUREMODEL_H

#include <QAbstractListModel>

class Node {
public:
  Node(const QString &name) : m_name(name) {}
  // TODO: symlink considerations
  // parentNode is clearly always a directory
private:
  Node *m_parentNode;
  QString m_name;
};

class PictureModel : public QAbstractListModel
{
    Q_OBJECT
public:
    enum PictureRoles {
        PathRole = Qt::UserRole + 1
    };

    static PictureModel* instance();
    bool setModelRoot(const QString &root);
    int rowCount(const QModelIndex & parent = QModelIndex()) const;

    Q_INVOKABLE QString randomPicture() const;
    QVariant data(const QModelIndex & index, int role = Qt::DisplayRole) const;

    bool addPath(const QString &path);
    void addSupportedExtension(const QString &extension);
protected:
    QHash<int, QByteArray> roleNames() const;
private:
    static PictureModel* model;
    PictureModel(QObject *parent = 0);
    QList<Node> nodes;
    QStringList paths;
    QStringList extensions;
};

#endif // PICTUREMODEL_H
