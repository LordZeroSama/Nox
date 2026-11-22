// Nox Home - backend implementation.
#include "launcher.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QMap>
#include <QProcess>
#include <QSettings>
#include <QStandardPaths>
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
    m_statusTimer.setInterval(5000);
    connect(&m_statusTimer, &QTimer::timeout, this, &Launcher::refreshOnline);
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
    // Hidden window = no rendering: the game gets all the CPU/GPU time.
    m_statusTimer.stop();
    emit hideRequested();
}

void Launcher::runTool(const QString &command)
{
    QProcess::startDetached("/bin/sh", {"-c", command});
}

void Launcher::refreshOnline()
{
    bool online = false;
    const QDir netDir("/sys/class/net");
    for (const QString &iface : netDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot)) {
        if (iface == "lo")
            continue;
        QFile state(netDir.filePath(iface + "/operstate"));
        if (state.open(QIODevice::ReadOnly) && state.readAll().trimmed() == "up") {
            online = true;
            break;
        }
    }
    if (online != m_online) {
        m_online = online;
        emit onlineChanged();
    }
}

void Launcher::setBusy(bool busy)
{
    if (busy == m_busy)
        return;
    m_busy = busy;
    emit busyChanged();
}
