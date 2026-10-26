#include "portlister.h"

#include <QSerialPortInfo>

QStringList PortLister::ports() const
{
    QStringList out;
    const auto infos = QSerialPortInfo::availablePorts();
    for (const auto &i : infos)
        out << i.portName();
    return out;
}

QString PortLister::description(const QString &port) const
{
    const auto infos = QSerialPortInfo::availablePorts();
    for (const auto &i : infos) {
        if (i.portName() == port) {
            QString d = i.description();
            return d.isEmpty() ? port : (port + " · " + d);
        }
    }
    return port;
}
