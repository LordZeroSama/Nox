// Nox Home - backend exposed to QML: app catalog, launching, system status.
#pragma once

#include <QObject>
#include <QMap>
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
    Q_PROPERTY(bool overlayEnabled READ overlayEnabled WRITE setOverlayEnabled NOTIFY overlayChanged)
    Q_PROPERTY(QVariantList overlayOptions READ overlayOptions NOTIFY overlayChanged)

public:
    explicit Launcher(QObject *parent = nullptr);

    QVariantList apps() const { return m_apps; }
    bool online() const { return m_online; }
    bool busy() const { return m_busy; }
    int signalBars() const { return m_signalBars; }
    QStringList storage() const { return m_storage; }
    bool overlayEnabled() const { return m_overlayEnabled; }
    void setOverlayEnabled(bool enabled);
    QVariantList overlayOptions() const;
    // Toggle one performance overlay item (MangoHud parameter name).
    Q_INVOKABLE void toggleOverlayOption(const QString &key);

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
    void overlayChanged();
    void showRequested();
    void launchFailed(const QString &name);

private:
    void refreshOnline();
    void refreshStorage();
    void loadOverlay();
    void saveOverlay() const;
    void setBusy(bool busy);

    QVariantList m_apps;
    bool m_online = false;
    bool m_busy = false;
    int m_signalBars = 0; // 0-4, wired connection = 4
    QStringList m_storage;
    bool m_overlayEnabled = false;
    QMap<QString, bool> m_overlayItems; // MangoHud parameter -> shown
    QTimer m_statusTimer;
};
