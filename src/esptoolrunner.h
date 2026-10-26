#pragma once

#include <QObject>
#include <QProcess>
#include <QStringList>

/**
 * 封装 esptool 的调用。
 * 通过 QProcess 启动外部 esptool，解析输出，抓取进度百分比。
 */
class EsptoolRunner : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString esptoolPath READ esptoolPath WRITE setEsptoolPath NOTIFY esptoolPathChanged)
    Q_PROPERTY(QString chip READ chip WRITE setChip NOTIFY chipChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(int progress READ progress NOTIFY progressChanged)

public:
    explicit EsptoolRunner(QObject *parent = nullptr);

    /** 由 main() 从 qrc 解出 esptool 后设置，构造函数优先使用它 */
    static void setBundledPath(const QString &path);

    QString esptoolPath() const { return m_esptoolPath; }
    void setEsptoolPath(const QString &p);

    QString chip() const { return m_chip; }
    void setChip(const QString &c);

    bool busy() const { return m_busy; }
    int progress() const { return m_progress; }

    /** 烧录固件。offset 形如 "0x0" */
    Q_INVOKABLE void flash(const QString &port, int baud,
                           const QString &firmware, const QString &offset);
    /** 整片擦除 */
    Q_INVOKABLE void erase(const QString &port);
    /** 读芯片信息 */
    Q_INVOKABLE void chipInfo(const QString &port);
    /** 中止当前任务 */
    Q_INVOKABLE void abort();

signals:
    void esptoolPathChanged();
    void chipChanged();
    void busyChanged();
    void progressChanged();
    void log(const QString &line);
    void finished(bool ok, const QString &message);

private:
    void start(const QStringList &args);
    void onReadyRead();
    void onFinished(int exitCode, QProcess::ExitStatus status);
    void reset();

    QProcess *m_proc = nullptr;
    QString   m_esptoolPath;
    QString   m_chip = QStringLiteral("esp32s3");
    bool      m_busy = false;
    int       m_progress = 0;
    QByteArray m_buffer;
};
