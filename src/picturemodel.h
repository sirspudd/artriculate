#ifndef PICTUREMODEL_H
#define PICTUREMODEL_H

#include <QAbstractListModel>
#include <QUrl>

class FSNode;

class PictureModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY (int count READ rowCount NOTIFY countChanged)
public:
    enum PictureRoles {
        PathRole = Qt::UserRole + 1
    };

    PictureModel(QObject *parent = nullptr);
    ~PictureModel();

    int rowCount(const QModelIndex & parent = QModelIndex()) const;

    Q_INVOKABLE QUrl randomPicture() const;
    QVariant data(const QModelIndex & index, int role = Qt::DisplayRole) const;

    Q_INVOKABLE void setModelRoot(const QString &root);

    void setSupportedExtensions(QStringList extensions);
    void addSupportedExtension(const QString &extension);
    void addModelNode(const FSNode *parent);
    QString qualifyNode(const FSNode *node) const;

signals:
    void countChanged();

protected:
    QHash<int, QByteArray> roleNames() const;

private:
    QList<const FSNode*> files;
    QStringList extensions;
};

#endif // PICTUREMODEL_H
