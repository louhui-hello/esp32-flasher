#pragma once

#include <QObject>
#include <QStringList>

/**
 * 列出本机的串口。
 */
class PortLister : public QObject
{
    Q_OBJECT
public:
    explicit PortLister(QObject *parent = nullptr) : QObject(parent) {}

    Q_INVOKABLE QStringList ports() const;
    Q_INVOKABLE QString description(const QString &port) const;
};
