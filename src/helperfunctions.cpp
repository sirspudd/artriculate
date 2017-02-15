#include "helperfunctions.h"

HelperFunctions::HelperFunctions(QObject *parent) : QObject(parent)
{
    const int kAccelerationFactor = 1;
    velocityArray = new qreal[kVelocityTableEntries];
    for(int i = 0; i < kVelocityTableEntries; i++) {
        velocityArray[i] = kAccelerationFactor*i/60;
    }
}

qreal HelperFunctions::velocityForTick(int tick)
{
    int tock = qBound(0, tick, kVelocityTableEntries - 1);
    return velocityArray[tock];
}
