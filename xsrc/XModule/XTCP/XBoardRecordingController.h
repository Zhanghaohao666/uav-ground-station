#pragma once

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QPointer>
#include <QTimer>
#include <QVariantMap>
#include <QStringList>

// Independent of VideoManager: UI visibility and local recording never stop
// a recording on the board. Only explicit API commands change board state.
class XBoardRecordingController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString address READ address NOTIFY configurationChanged)
    Q_PROPERTY(QString connectionCode READ connectionCode NOTIFY configurationChanged)
    Q_PROPERTY(bool rememberConnection READ rememberConnection NOTIFY configurationChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY changed)
    Q_PROPERTY(bool connected READ connected NOTIFY changed)
    Q_PROPERTY(QVariantMap status READ status NOTIFY changed)
    Q_PROPERTY(QString errorText READ errorText NOTIFY changed)
public:
    explicit XBoardRecordingController(QObject* parent = nullptr);
    ~XBoardRecordingController() override;
    QString address() const { return _address; }
    QString connectionCode() const { return _code; }
    bool rememberConnection() const { return _remember; }
    bool busy() const { return _busy; }
    bool connected() const { return _connected; }
    QVariantMap status() const { return _status; }
    QString errorText() const { return _error; }
    Q_INVOKABLE bool configure(const QString& address, const QString& code, bool remember);
    Q_INVOKABLE void refresh();
    Q_INVOKABLE void startSelected(const QStringList& keys);
    Q_INVOKABLE void stopSelected(const QStringList& keys);
    Q_INVOKABLE void stopAll();
signals:
    void changed();
    void configurationChanged();
private:
    void request(const QString& action, const QStringList& keys = {});
    void cancelRequest();
    QNetworkAccessManager _network;
    QTimer _poll;
    QPointer<QNetworkReply> _reply;
    QString _address = QStringLiteral("192.168.2.36");
    QString _code;
    bool _remember = true;
    bool _busy = false;
    bool _connected = false;
    bool _operationError = false;
    QVariantMap _status;
    QString _error;
};
