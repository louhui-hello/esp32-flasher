#include "serialmonitor.h"

SerialMonitor::SerialMonitor(QObject *parent)
    : QObject(parent)
{
    connect(&m_serial, &QSerialPort::readyRead, this, [this]() {
        QByteArray d = m_serial.readAll();
        if (d.isEmpty())
            return;
        // ESP-IDF 默认输出 UTF-8；若解出来有替换字符，再退回本地编码（GBK）
        QString s = QString::fromUtf8(d);
        if (s.contains(QChar::ReplacementCharacter))
            s = QString::fromLocal8Bit(d);
        emit received(s);
    });

    connect(&m_serial, &QSerialPort::errorOccurred, this, [this](QSerialPort::SerialPortError e) {
        if (e == QSerialPort::NoError) return;
        emit error(m_serial.errorString());
        if (e == QSerialPort::ResourceError || e == QSerialPort::DeviceNotFoundError) {
            close();
        }
    });
}

bool SerialMonitor::open(const QString &port, int baud)
{
    if (m_serial.isOpen())
        m_serial.close();

    m_serial.setPortName(port);
    m_serial.setBaudRate(baud);
    m_serial.setDataBits(QSerialPort::Data8);
    m_serial.setStopBits(QSerialPort::OneStop);
    m_serial.setParity(QSerialPort::NoParity);
    m_serial.setFlowControl(QSerialPort::NoFlowControl);

    if (!m_serial.open(QIODevice::ReadWrite)) {
        emit error(m_serial.errorString());
        return false;
    }

    m_baudrate = baud;
    emit openChanged();
    return true;
}

void SerialMonitor::close()
{
    if (!m_serial.isOpen()) return;
    m_serial.close();
    emit openChanged();
}

void SerialMonitor::send(const QString &text)
{
    if (!m_serial.isOpen()) { emit error("串口未打开"); return; }
    m_serial.write(text.toUtf8());
}

void SerialMonitor::sendLine(const QString &text)
{
    send(text + "\r\n");
}
