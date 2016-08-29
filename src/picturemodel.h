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
        NameRole = Qt::UserRole + 1,
        PathRole,
        SizeRole,
        RatioRole
    };
    Q_ENUM(PictureRoles)

    PictureModel(QObject *parent = nullptr);
    ~PictureModel();

    int rowCount(const QModelIndex & parent = QModelIndex()) const;
    Q_INVOKABLE QVariant data(const int &row, int role = PathRole) const { return data(index(row, 0), role); }
    QVariant data(const QModelIndex & index, int role = PathRole) const;
signals:
    void countChanged();

protected:
    QHash<int, QByteArray> roleNames() const;

private:
    class PictureModelPrivate;
    PictureModelPrivate *d;
};

#endif // PICTUREMODEL_H
