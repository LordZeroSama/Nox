// Nox Home - backend implementation.
#include "launcher.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QMap>
#include <QProcess>
#include <QSettings>
#include <QStandardPaths>
#include <QStorageInfo>
#include <QTextStream>
#include <cmath>
#include <QUrl>

#ifndef NOX_HOME_DATA_DIR
#define NOX_HOME_DATA_DIR "/usr/share/nox-home"
#endif

namespace {

// App entries are small INI files; a user file with the same name overrides
// the system one (persistent /home lets the user add or customize tiles).
QStringList appDirectories()
{
    const QString userDir =
        QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + "/nox-home/apps";
    return {QStringLiteral(NOX_HOME_DATA_DIR "/apps"), userDir};
}

QVariantMap readAppFile(const QString &path)
{
    QSettings ini(path, QSettings::IniFormat);
    ini.beginGroup("App");
    QVariantMap app;
    app["name"] = ini.value("Name", QFileInfo(path).baseName()).toString();
    app["subtitle"] = ini.value("Subtitle").toString();
    app["exec"] = ini.value("Exec").toString();
    app["color"] = ini.value("Color", "#3c3489").toString();
    app["kind"] = ini.value("Kind", "app").toString();
    app["action"] = ini.value("Action", "Jouer").toString();

    QString image = ini.value("Image").toString();
    if (!image.isEmpty() && QDir::isRelativePath(image))
        image = QFileInfo(path).absolutePath() + "/" + image;
    app["image"] = QFile::exists(image) ? QUrl::fromLocalFile(image).toString() : QString();
    return app;
}

} // namespace

Launcher::Launcher(QObject *parent)
    : QObject(parent)
{
    reloadApps();
    refreshOnline();
    refreshStorage();
    m_statusTimer.setInterval(5000);
    connect(&m_statusTimer, &QTimer::timeout, this, [this] {
        refreshOnline();
        refreshStorage();
    });
    m_statusTimer.start();
}

void Launcher::reloadApps()
{
    QMap<QString, QString> filesByName; // sorted by file name, user files win
    for (const QString &dirPath : appDirectories()) {
        const QDir dir(dirPath);
        for (const QFileInfo &info : dir.entryInfoList({"*.conf"}, QDir::Files))
            filesByName[info.fileName()] = info.absoluteFilePath();
    }

    m_apps.clear();
    for (const QString &path : filesByName)
        m_apps.append(readAppFile(path));
    emit appsChanged();
}

void Launcher::launch(int index)
{
    if (index < 0 || index >= m_apps.size() || m_busy)
        return;

    const QVariantMap app = m_apps.at(index).toMap();
    const QString command = app.value("exec").toString();
    if (command.isEmpty())
        return;

    auto *process = new QProcess(this);
    process->setProgram("/bin/sh");
    process->setArguments({"-c", command});
    process->setProcessChannelMode(QProcess::ForwardedChannels);

    connect(process, &QProcess::finished, this, [this, process] {
        process->deleteLater();
        setBusy(false);
        m_statusTimer.start();
        emit showRequested();
    });
    connect(process, &QProcess::errorOccurred, this, [this, process, app](QProcess::ProcessError error) {
        if (error != QProcess::FailedToStart)
            return;
        process->deleteLater();
        setBusy(false);
        m_statusTimer.start();
        emit showRequested();
        emit launchFailed(app.value("name").toString());
    });

    setBusy(true);
    process->start();
    // The app window covers the home screen (fullscreen window rule in labwc):
    // the compositor stops sending frames to the hidden home screen, and the
    // status polling pauses, so the game gets the CPU/GPU time.
    m_statusTimer.stop();
}

void Launcher::runTool(const QString &command)
{
    QProcess::startDetached("/bin/sh", {"-c", command});
}

void Launcher::refreshOnline()
{
    bool online = false;
    bool wiredUp = false;
    QString wirelessUp;
    const QDir netDir("/sys/class/net");
    for (const QString &iface : netDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot)) {
        if (iface == "lo")
            continue;
        QFile state(netDir.filePath(iface + "/operstate"));
        if (!state.open(QIODevice::ReadOnly) || state.readAll().trimmed() != "up")
            continue;
        online = true;
        if (QFileInfo::exists(netDir.filePath(iface + "/wireless")))
            wirelessUp = iface;
        else
            wiredUp = true;
    }

    int bars = 0;
    if (wiredUp) {
        bars = 4;
    } else if (!wirelessUp.isEmpty()) {
        // /proc/net/wireless: "wlan0: 0000   54.  -56.  -256 ..." (link quality out of 70)
        QFile wireless("/proc/net/wireless");
        if (wireless.open(QIODevice::ReadOnly)) {
            QTextStream in(&wireless);
            while (!in.atEnd()) {
                const QStringList fields = in.readLine().simplified().split(' ');
                if (fields.size() > 2 && fields.at(0) == wirelessUp + ":") {
                    const double quality = QString(fields.at(2)).remove('.').toDouble();
                    bars = qBound(1, int(std::ceil(quality / 70.0 * 4.0)), 4);
                }
            }
        }
        if (bars == 0)
            bars = 1;
    }

    if (online != m_online || bars != m_signalBars) {
        m_online = online;
        m_signalBars = bars;
        emit onlineChanged();
    }
}

void Launcher::refreshStorage()
{
    // One line per real disk partition: "used - total GB [percent%]"
    QStringList lines;
    QStorageInfo rootFallback;
    for (const QStorageInfo &volume : QStorageInfo::mountedVolumes()) {
        if (!volume.isValid() || !volume.isReady())
            continue;
        if (volume.rootPath() == "/")
            rootFallback = volume;
        const QString device = QString::fromUtf8(volume.device());
        if (!device.startsWith("/dev/") || device.startsWith("/dev/loop"))
            continue;
        if (volume.bytesTotal() < 512LL * 1024 * 1024)
            continue; // skip tiny partitions (EFI, ...)
        const double totalGb = volume.bytesTotal() / 1e9;
        const double usedGb = (volume.bytesTotal() - volume.bytesAvailable()) / 1e9;
        const int percent = int(std::round(usedGb / totalGb * 100.0));
        lines << QStringLiteral("%1 - %2 GB [%3%]")
                     .arg(std::round(usedGb)).arg(std::round(totalGb)).arg(percent);
    }
    // No persistent partition yet: show the RAM-backed system space instead.
    if (lines.isEmpty() && rootFallback.isValid() && rootFallback.bytesTotal() > 0) {
        const double totalGb = rootFallback.bytesTotal() / 1e9;
        const double usedGb = (rootFallback.bytesTotal() - rootFallback.bytesAvailable()) / 1e9;
        lines << QStringLiteral("%1 - %2 GB [%3%]")
                     .arg(usedGb, 0, 'f', 1).arg(totalGb, 0, 'f', 1)
                     .arg(int(std::round(usedGb / totalGb * 100.0)));
    }
    if (lines != m_storage) {
        m_storage = lines;
        emit storageChanged();
    }
}

void Launcher::setBusy(bool busy)
{
    if (busy == m_busy)
        return;
    m_busy = busy;
    emit busyChanged();
}
