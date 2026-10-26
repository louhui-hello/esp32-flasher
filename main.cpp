#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QIcon>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QStandardPaths>

#include "src/esptoolrunner.h"
#include "src/serialmonitor.h"
#include "src/portlister.h"

/**
 * 把 qrc 里的 esptool.exe 解到本地，避免依赖外部文件。
 * 优先解到 exe 同级目录（真正的绿色）；目录不可写时才退到用户缓存。
 * 已经解过且大小一致就直接复用。
 */
static QString ensureBundledEsptool()
{
    QFile res(QStringLiteral(":/tools/esptool.exe"));
    if (!res.open(QIODevice::ReadOnly)) {
        qWarning("qrc 中没有 esptool.exe");
        return QString();
    }

    const QString appDir = QCoreApplication::applicationDirPath();
    QString dir = appDir;
    if (!QFileInfo(appDir).isWritable()) {
        dir = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation);
        QDir().mkpath(dir);
    }
    const QString target = dir + QStringLiteral("/esptool.exe");

    if (QFileInfo(target).size() == res.size())
        return target;

    QFile out(target + QStringLiteral(".tmp"));
    if (!out.open(QIODevice::WriteOnly)) {
        qWarning("无法写入 %s", qPrintable(target));
        return QString();
    }
    out.write(res.readAll());
    out.close();

    QFile::remove(target);
    if (!QFile::rename(target + QStringLiteral(".tmp"), target))
        return QString();

    return target;
}

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName("ESP32 Flasher");
    app.setOrganizationName("louhui-hello");

    // 单文件模式：先把内嵌的 esptool 解出来
    const QString esptool = ensureBundledEsptool();
    if (!esptool.isEmpty())
        EsptoolRunner::setBundledPath(esptool);

    qmlRegisterType<EsptoolRunner>("EspFlasher", 1, 0, "EsptoolRunner");
    qmlRegisterType<SerialMonitor>("EspFlasher", 1, 0, "SerialMonitor");
    qmlRegisterType<PortLister>("EspFlasher", 1, 0, "PortLister");

    QQmlApplicationEngine engine;
    engine.loadFromModule("EspFlasher", "Main");
    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
