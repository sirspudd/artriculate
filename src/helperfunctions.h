#ifndef HELPERFUNCTIONS_H
#define HELPERFUNCTIONS_H

#include <QObject>
#include <qglobal.h>

class HelperFunctions : public QObject
{
    Q_OBJECT
public:
    explicit HelperFunctions(QObject *parent = nullptr);
    Q_SCRIPTABLE qreal velocityForTick(int tick);

signals:

public slots:
private:
    const int kVelocityTableEntries = 600;
    qreal* velocityArray;
};

#endif // HELPERFUNCTIONS_H
