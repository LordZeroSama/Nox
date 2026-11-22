// Nox Home - backend exposed to QML: app catalog, launching, system status.
#pragma once

#include <QObject>
#include <QStringList>
#include <QTimer>
#include <QVariantList>

class Launcher : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList apps READ apps NOTIFY appsChanged)
    Q_PROPERTY(bool online READ online NOTIFY onlineChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(int signalBars READ signalBars NOTIFY onlineChanged)
    Q_PROPERTY(QStringList storage READ storage NOTIFY storageChanged)

public:
    explicit Launcher(QObject *parent = nullptr);

    QVariantList apps() const { return m_apps; }
    bool online() const { return m_online; }
    bool busy() const { return m_busy; }
    int signalBars() const { return m_signalBars; }
    QStringList storage() const { return m_storage; }

    // Launch the app at index: it opens fullscreen on top of the home screen,
    // which comes back to the front when the app exits.
    Q_INVOKABLE void launch(int index);
    // Run a tool command (terminal, Wi-Fi, ...) on top of the home screen.
    Q_INVOKABLE void runTool(const QString &command);
    Q_INVOKABLE void reloadApps();

    void requestShow() { emit showRequested(); }

signals:
    void appsChanged();
    void onlineChanged();
    void busyChanged();
    void storageChanged();
    void showRequested();
    void launchFailed(const QString &name);

private:
    void refreshOnline();
    void refreshStorage();
    void setBusy(bool busy);

    QVariantList m_apps;
    bool m_online = false;
    bool m_busy = false;
    int m_signalBars = 0; // 0-4, wired connection = 4
    QStringList m_storage;
    QTimer m_statusTimer;
};
