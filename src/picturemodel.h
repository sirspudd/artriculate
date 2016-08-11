#ifndef PICTUREMODEL_H
#define PICTUREMODEL_H

#include <QAbstractListModel>
#include <QUrl>

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

signals:
    void countChanged();

protected:
    QHash<int, QByteArray> roleNames() const;

private:
    class PictureModelPrivate;
    PictureModelPrivate *d;
};

#endif // PICTUREMODEL_H
