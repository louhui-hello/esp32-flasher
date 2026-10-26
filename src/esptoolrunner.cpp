#include "esptoolrunner.h"

#include <QCoreApplication>
#include <QRegularExpression>
#include <QStandardPaths>
#include <QFileInfo>
#include <QDebug>

static QString g_bundledEsptool;

void EsptoolRunner::setBundledPath(const QString &path)
{
    g_bundledEsptool = path;
}

EsptoolRunner::EsptoolRunner(QObject *parent)
    : QObject(parent)
{
    // ① 优先用从 qrc 解出来的 esptool（单文件发布）
    // ② 否则找同目录下的 esptool.exe（便携版）
    if (!g_bundledEsptool.isEmpty() && QFileInfo::exists(g_bundledEsptool)) {
        m_esptoolPath = g_bundledEsptool;
    } else {
        QString guess = QCoreApplication::applicationDirPath() + "/esptool.exe";
        if (QFileInfo::exists(guess))
            m_esptoolPath = guess;
    }

    m_proc = new QProcess(this);
    m_proc->setProcessChannelMode(QProcess::MergedChannels);
    connect(m_proc, &QProcess::readyRead, this, &EsptoolRunner::onReadyRead);
    connect(m_proc, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &EsptoolRunner::onFinished);
    connect(m_proc, &QProcess::errorOccurred, this, [this](QProcess::ProcessError e) {
        if (e == QProcess::FailedToStart) {
            emit log("ERROR: 无法启动 esptool，请检查路径");
            emit finished(false, "esptool 启动失败");
            reset();
        }
    });
}

void EsptoolRunner::setEsptoolPath(const QString &p)
{
    if (m_esptoolPath == p) return;
    m_esptoolPath = p;
    emit esptoolPathChanged();
}

void EsptoolRunner::setChip(const QString &c)
{
    if (m_chip == c) return;
    m_chip = c;
    emit chipChanged();
}

void EsptoolRunner::flash(const QString &port, int baud,
                          const QString &firmware, const QString &offset)
{
    if (m_busy) { emit log("WARN: 已有任务在跑"); return; }
    if (m_esptoolPath.isEmpty() || !QFileInfo::exists(m_esptoolPath)) {
        emit log("ERROR: 找不到 esptool.exe，请在设置里指定路径");
        emit finished(false, "esptool 未配置");
        return;
    }
    if (!QFileInfo::exists(firmware)) {
        emit log("ERROR: 固件文件不存在: " + firmware);
        emit finished(false, "固件不存在");
        return;
    }

    QStringList args = {
        "--chip", m_chip,
        "--port", port,
        "--baud", QString::number(baud),
        "write-flash",
                offset,
        firmware
    };
    start(args);
}

void EsptoolRunner::erase(const QString &port)
{
    if (m_busy) { emit log("WARN: 已有任务在跑"); return; }
    QStringList args = {
        "--chip", m_chip,
        "--port", port,
        "erase-flash"
    };
    start(args);
}

void EsptoolRunner::chipInfo(const QString &port)
{
    if (m_busy) { emit log("WARN: 已有任务在跑"); return; }
    QStringList args = {
        "--chip", m_chip,
        "--port", port,
        "chip-id"
    };
    start(args);
}

void EsptoolRunner::abort()
{
    if (m_busy && m_proc->state() != QProcess::NotRunning) {
        emit log("用户中止");
        m_proc->kill();
    }
}

void EsptoolRunner::start(const QStringList &args)
{
    if (m_esptoolPath.isEmpty() || !QFileInfo::exists(m_esptoolPath)) {
        emit log("ERROR: 找不到 esptool.exe，请在 esptool 一栏指定路径");
        emit finished(false, "esptool 未配置");
        return;
    }

    m_busy = true;
    m_progress = 0;
    m_buffer.clear();
    emit busyChanged();
    emit progressChanged();

    emit log("> " + m_esptoolPath + " " + args.join(' '));
    m_proc->start(m_esptoolPath, args);
}

void EsptoolRunner::onReadyRead()
{
    QByteArray chunk = m_proc->readAll();
    m_buffer.append(chunk);

    // 按行切分
    while (true) {
        int nl = m_buffer.indexOf('\n');
        if (nl < 0) break;
        QByteArray line = m_buffer.left(nl);
        m_buffer.remove(0, nl + 1);

        QString s = QString::fromLocal8Bit(line).trimmed();
        if (s.isEmpty()) continue;

        // 抓进度。两种格式都要认：
        //   esptool v4.x :  "Writing at 0x0000... (45 %)"
        //   esptool v5.x :  "Writing at 0x0000 ===== 13.8% 16.00kB/116.11kB [0s]"
        static const QRegularExpression re(R"((\d+(?:\.\d+)?)\s*%)");
        auto m = re.match(s);
        if (m.hasMatch()) {
            int v = qRound(m.captured(1).toDouble());
            v = qBound(0, v, 100);
            if (v != m_progress) {
                m_progress = v;
                emit progressChanged();
            }
        }
        emit log(s);
    }
}

void EsptoolRunner::onFinished(int exitCode, QProcess::ExitStatus status)
{
    // 把剩余缓冲刷出来
    if (!m_buffer.isEmpty()) {
        emit log(QString::fromLocal8Bit(m_buffer).trimmed());
        m_buffer.clear();
    }

    bool ok = (status == QProcess::NormalExit && exitCode == 0);
    emit finished(ok, ok ? QStringLiteral("成功") : QStringLiteral("失败 (exit %1)").arg(exitCode));
    reset();
}

void EsptoolRunner::reset()
{
    m_busy = false;
    emit busyChanged();
}
