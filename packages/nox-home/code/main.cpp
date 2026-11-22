// Nox Home - console-style fullscreen launcher for Nox OS.
// Running "nox-home" again brings the existing instance back to the front.
#include <QGuiApplication>
#include <QLocalServer>
#include <QLocalSocket>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>

#include "launcher.h"

namespace {
constexpr auto kSocketName = "nox-home";

bool notifyRunningInstance()
{
    QLocalSocket probe;
    probe.connectToServer(kSocketName);
    if (!probe.waitForConnected(200))
        return false;
    probe.write("show");
    probe.waitForBytesWritten(200);
    return true;
}
} // namespace

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName("nox-home");
    app.setDesktopFileName("nox-home");

    if (notifyRunningInstance())
        return 0;

    QLocalServer::removeServer(kSocketName);
    QLocalServer server;
    server.listen(kSocketName);

    Launcher launcher;
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("launcher", &launcher);
    engine.load(QUrl(QStringLiteral("qrc:/qml/Main.qml")));
    if (engine.rootObjects().isEmpty())
        return 1;

    auto *window = qobject_cast<QQuickWindow *>(engine.rootObjects().constFirst());
    if (!window)
        return 1;

    auto showHome = [window] {
        window->showFullScreen();
        window->raise();
        window->requestActivate();
    };

    QObject::connect(&server, &QLocalServer::newConnection, &launcher, [&server, &launcher] {
        while (QLocalSocket *client = server.nextPendingConnection()) {
            client->deleteLater();
            launcher.requestShow();
        }
    });
    QObject::connect(&launcher, &Launcher::showRequested, window, showHome);

    showHome();
    return app.exec();
}
