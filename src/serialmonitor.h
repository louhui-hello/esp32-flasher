#pragma once

#include <QObject>
#include <QSerialPort>
#include <QStringList>

/**
 * 串口监视器：打开/关闭端口，收发数据。
 */
class SerialMonitor : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool opened READ isOpen NOTIFY openChanged)
    Q_PROPERTY(int baudrate READ baudrate WRITE setBaudrate NOTIFY baudrateChanged)
    Q_PROPERTY(QString portName READ portName NOTIFY openChanged)

public:
    explicit SerialMonitor(QObject *parent = nullptr);

    bool isOpen() const { return m_serial.isOpen(); }
    int baudrate() const { return m_baudrate; }
    void setBaudrate(int b) { if (m_baudrate != b) { m_baudrate = b; emit baudrateChanged(); } }
    QString portName() const { return m_serial.portName(); }

    Q_INVOKABLE bool open(const QString &port, int baud);
    Q_INVOKABLE void close();
    Q_INVOKABLE void send(const QString &text);
    Q_INVOKABLE void sendLine(const QString &text);   // 自动加 \r\n

signals:
    void openChanged();
    void baudrateChanged();
    void received(const QString &text);
    void error(const QString &message);

private:
    QSerialPort m_serial;
    int m_baudrate = 115200;
};
