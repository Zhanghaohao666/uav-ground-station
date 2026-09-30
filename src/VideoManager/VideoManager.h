/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


#ifndef VideoManager_H
#define VideoManager_H

#include <QObject>
#include <QTimer>
#include <QTime>
#include <QUrl>
#include <QQuickItem>
#include <QPointer>

#include "QGCMAVLink.h"
#include "QGCLoggingCategory.h"
#include "VideoReceiver.h"
#include "QGCToolbox.h"
#include "SubtitleWriter.h"

Q_DECLARE_LOGGING_CATEGORY(VideoManagerLog)

class VideoSettings;
class Vehicle;
class Joystick;

class VideoManager : public QGCTool
{
    Q_OBJECT

public:
    VideoManager    (QGCApplication* app, QGCToolbox* toolbox);
    virtual ~VideoManager   ();

    Q_PROPERTY(bool             hasVideo                READ    hasVideo                                    NOTIFY hasVideoChanged)
    Q_PROPERTY(bool             isGStreamer             READ    isGStreamer                                 NOTIFY isGStreamerChanged)
    Q_PROPERTY(bool             isUvc                   READ    isUvc                                       NOTIFY isUvcChanged)
    Q_PROPERTY(bool             isTaisync               READ    isTaisync       WRITE   setIsTaisync        NOTIFY isTaisyncChanged)
    Q_PROPERTY(QString          uvcVideoSourceID        READ    uvcVideoSourceID                            NOTIFY uvcVideoSourceIDChanged)
    Q_PROPERTY(bool             uvcEnabled              READ    uvcEnabled                                  CONSTANT)
    Q_PROPERTY(bool             fullScreen              READ    fullScreen      WRITE   setfullScreen       NOTIFY fullScreenChanged)
    Q_PROPERTY(VideoReceiver*   videoReceiver           READ    videoReceiver                               CONSTANT)
    Q_PROPERTY(VideoReceiver*   thermalVideoReceiver    READ    thermalVideoReceiver                        CONSTANT)
    Q_PROPERTY(VideoReceiver*   videoReceiver3          READ    videoReceiver3                              CONSTANT)
    Q_PROPERTY(VideoReceiver*   videoReceiver4          READ    videoReceiver4                              CONSTANT)
    Q_PROPERTY(VideoReceiver*   videoReceiver5          READ    videoReceiver5                              CONSTANT)
    Q_PROPERTY(VideoReceiver*   videoReceiver6          READ    videoReceiver6                              CONSTANT)
    Q_PROPERTY(double           aspectRatio             READ    aspectRatio                                 NOTIFY aspectRatioChanged)
    Q_PROPERTY(double           thermalAspectRatio      READ    thermalAspectRatio                          NOTIFY aspectRatioChanged)
    Q_PROPERTY(double           hfov                    READ    hfov                                        NOTIFY aspectRatioChanged)
    Q_PROPERTY(double           thermalHfov             READ    thermalHfov                                 NOTIFY aspectRatioChanged)
    Q_PROPERTY(bool             autoStreamConfigured    READ    autoStreamConfigured                        NOTIFY autoStreamConfiguredChanged)
    Q_PROPERTY(bool             hasThermal              READ    hasThermal                                  NOTIFY decodingChanged)
    Q_PROPERTY(QString          imageFile               READ    imageFile                                   NOTIFY imageFileChanged)
    Q_PROPERTY(bool             streaming               READ    streaming                                   NOTIFY streamingChanged)
    Q_PROPERTY(bool             decoding                READ    decoding                                    NOTIFY decodingChanged)
    Q_PROPERTY(bool             recording               READ    recording                                   NOTIFY recordingChanged)
    Q_PROPERTY(QSize            videoSize               READ    videoSize                                   NOTIFY videoSizeChanged)

    virtual bool        hasVideo            ();
    virtual bool        isGStreamer         ();
    virtual bool        isUvc               ();
    virtual bool        isTaisync           () { return _isTaisync; }
    virtual bool        fullScreen          () { return _fullScreen; }
    virtual QString     uvcVideoSourceID    () { return _uvcVideoSourceID; }
    virtual double      aspectRatio         ();
    virtual double      thermalAspectRatio  ();
    virtual double      hfov                ();
    virtual double      thermalHfov         ();
    virtual bool        autoStreamConfigured();
    virtual bool        hasThermal          ();
    virtual QString     imageFile           ();

    bool streaming(void) {
        return _streaming;
    }

    bool decoding(void) {
        return _decoding;
    }

    bool recording(void) {
        return _recording;
    }

    QSize videoSize(void) {
        const quint32 size = _videoSize;
        return QSize((size >> 16) & 0xFFFF, size & 0xFFFF);
    }

// FIXME: AV: they should be removed after finishing multiple video stream support
// new arcitecture does not assume direct access to video receiver from QML side, even if it works for now
    virtual VideoReceiver*  videoReceiver           () { return _videoReceiver[0]; }
    virtual VideoReceiver*  thermalVideoReceiver    () { return _videoReceiver[1]; }
    virtual VideoReceiver*  videoReceiver3          () { return _videoReceiver[2]; }
    virtual VideoReceiver*  videoReceiver4          () { return _videoReceiver[3]; }
    virtual VideoReceiver*  videoReceiver5          () { return _videoReceiver[4]; }
    virtual VideoReceiver*  videoReceiver6          () { return _videoReceiver[5]; }

#if defined(QGC_DISABLE_UVC)
    virtual bool        uvcEnabled          () { return false; }
#else
    virtual bool        uvcEnabled          ();
#endif

    virtual void        setfullScreen       (bool f);
    virtual void        setIsTaisync        (bool t) { _isTaisync = t;  emit isTaisyncChanged(); }

    // Override from QGCTool
    virtual void        setToolbox          (QGCToolbox *toolbox);

    Q_PROPERTY(int requestedStreamMask READ requestedStreamMask NOTIFY requestedStreamMaskChanged)
    int requestedStreamMask() const;
    Q_INVOKABLE void setVideoStreamVisible(int id, bool visible);

    Q_INVOKABLE void startVideo     ();
    Q_INVOKABLE void stopVideo      ();
    Q_INVOKABLE void startVideoStream(int id);
    Q_INVOKABLE void stopVideoStream(int id);
    Q_INVOKABLE void initVideoSinks ();
    Q_INVOKABLE void bindVideoSink(QQuickItem* widget, int id);

    Q_INVOKABLE void startRecording (const QString& videoFile = QString());
    Q_INVOKABLE void stopRecording  ();

    Q_INVOKABLE void grabImage(const QString& imageFile = QString());

signals:
    void requestedStreamMaskChanged();
    void hasVideoChanged            ();
    void isGStreamerChanged         ();
    void isUvcChanged               ();
    void uvcVideoSourceIDChanged    ();
    void fullScreenChanged          ();
    void isAutoStreamChanged        ();
    void isTaisyncChanged           ();
    void aspectRatioChanged         ();
    void autoStreamConfiguredChanged();
    void imageFileChanged           ();
    void streamingChanged           ();
    void decodingChanged            ();
    void recordingChanged           ();
    void recordingStarted           ();
    void videoSizeChanged           ();

protected slots:
    void _videoSourceChanged        ();
    void _udpPortChanged            ();
    void _rtspUrlChanged            ();
    void _rtspUrl2Changed            ();
    void _rtspUrl3Changed            ();
    void _rtspUrl4Changed            ();
    void _rtspUrl5Changed            ();
    void _rtspUrl6Changed            ();
    void _tcpUrlChanged             ();
    void _lowLatencyModeChanged     ();
    void _updateUVC                 ();
    void _setActiveVehicle          (Vehicle* vehicle);
    void _aspectRatioChanged        ();
    void _communicationLostChanged  (bool communicationLost);

protected:
    friend class FinishVideoInitialization;
    friend class InitVideoSinks;
    friend class BindVideoSink;

    static constexpr int kStreamCount = 6;

    void _initVideo                 ();
    void _initVideoSink             (QQuickItem* widget, unsigned id);
    bool _updateSettings            (unsigned id);
    bool _updateVideoUri            (unsigned id, const QString& uri);
    void _cleanupOldVideos          ();
    void _restartAllVideos          ();
    void _restartVideo              (unsigned id);
    bool _receiverWanted(unsigned id) const;
    void _syncReceiver(unsigned id);
    void _loadRequestedStreams();
    void _saveRequestedStreams();
    void _handleStartComplete(unsigned id, VideoReceiver::STATUS status);
    void _handleStopComplete(unsigned id, VideoReceiver::STATUS status);
    void _startReceiver             (unsigned id);
    void _stopReceiver              (unsigned id);

protected:
    QString                 _videoFile;
    QString                 _imageFile;
    SubtitleWriter          _subtitleWriter;
    bool                    _isTaisync              = false;
    VideoReceiver*          _videoReceiver[kStreamCount]       = {};
    void*                   _videoSink[kStreamCount]           = {};
    QString                 _videoUri[kStreamCount];
    // FIXME: AV: _videoStarted seems to be access from 3 different threads, from time to time
    // 1) Video Receiver thread
    // 2) Video Manager/main app thread
    // 3) Qt rendering thread (during video sink creation process which should happen in this thread)
    // It works for now but...
    bool                    _videoStarted[kStreamCount]        = {};
    // User choice persists; visibility is temporary and never changes that choice.
    bool                    _videoEnabled[kStreamCount]        = {};
    bool                    _videoVisible[kStreamCount]        = {};
    bool                    _videoStarting[kStreamCount]       = {};
    bool                    _videoStopping[kStreamCount]       = {};
    QTimer*                 _videoRetryTimer[kStreamCount]     = {};
    QPointer<QQuickItem>     _videoSinkWidget[kStreamCount];
    bool                    _videoSuspended = false;
    bool                    _lowLatencyStreaming[kStreamCount] = {};
    QAtomicInteger<bool>    _streaming              = false;
    QAtomicInteger<bool>    _decoding               = false;
    QAtomicInteger<bool>    _recording              = false;
    QAtomicInteger<quint32> _videoSize              = 0;
    VideoSettings*          _videoSettings          = nullptr;
    QString                 _uvcVideoSourceID;
    bool                    _fullScreen             = false;
    Vehicle*                _activeVehicle          = nullptr;
};

#endif
