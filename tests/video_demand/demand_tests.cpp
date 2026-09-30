#include <QtTest>
#include <QJSEngine>
#include <QQmlEngine>
#include <QFile>
#include <QQuickItem>
#include <QSettings>
#include <QTemporaryDir>
#include <QLoggingCategory>
#include <QPointer>
#include <QTimer>
#include "../../src/VideoReceiver/VideoReceiver.h"
Q_LOGGING_CATEGORY(VideoManagerLog, "demand.tests")
struct Fact { QVariant value; QVariant rawValue() const {return value;} void setRawValue(QVariant v) {value=v;} };
struct VideoSettings {
 static constexpr const char* videoSourceRTSP="RTSP", *videoDisabled="Disabled", *videoSourceNoVideo="No Video";
 Fact enabled{true}, source{QString("RTSP")}, timeout{5};
 Fact* streamEnabled(){return &enabled;} Fact* videoSource(){return &source;} Fact* rtspTimeout(){return &timeout;}
 bool streamConfigured(){return true;}
};
struct Core { int creates=0; void* createVideoSink(QObject*,QQuickItem*){++creates;return reinterpret_cast<void*>(quintptr(creates));} };
struct Toolbox { Core core; Core* corePlugin(){return &core;} };
struct App { Toolbox box; bool runningUnitTests(){return false;} Toolbox* toolbox(){return &box;} } app;
App* qgcApp(){return &app;}
namespace GStreamer { int releases=0; void releaseVideoSink(void*){++releases;} }
class FakeReceiver : public VideoReceiver {
public:
 int starts=0,stops=0,decodes=0; QString lastUri;
 void start(const QString& uri,unsigned,int) override {++starts;lastUri=uri;}
 void stop() override {++stops;}
 void startDecoding(void*) override {++decodes;}
 void stopDecoding() override {}
 void startRecording(const QString&,FILE_FORMAT) override {}
 void stopRecording() override {}
 void takeScreenshot(const QString&) override {}
 void finishStart(STATUS s=STATUS_OK){emit onStartComplete(s);}
 void finishStop(){emit onStopComplete(STATUS_OK);}
};
class VideoManager : public QObject {
 Q_OBJECT
public:
 #include "stream_count.inc"
 VideoSettings settings; VideoSettings* _videoSettings=&settings;
 FakeReceiver receivers[kStreamCount]; VideoReceiver* _videoReceiver[kStreamCount]={};
 void* _videoSink[kStreamCount]={}; QPointer<QQuickItem> _videoSinkWidget[kStreamCount];
 QString _videoUri[kStreamCount], configuredUri[kStreamCount];
 bool _videoStarted[kStreamCount]={},_videoEnabled[kStreamCount]={},_videoVisible[kStreamCount]={},
      _videoStarting[kStreamCount]={},_videoStopping[kStreamCount]={},_lowLatencyStreaming[kStreamCount]={};
 bool _videoSuspended=false; QTimer* _videoRetryTimer[kStreamCount]={};
 VideoManager(){
  _loadRequestedStreams();
  for(int i=0;i<kStreamCount;++i){
   _videoReceiver[i]=&receivers[i];
   _videoUri[i]=configuredUri[i]=QString("rtsp://127.0.0.1:8554/%1").arg(i);
   _videoRetryTimer[i]=new QTimer(this);_videoRetryTimer[i]->setSingleShot(true);_videoRetryTimer[i]->setInterval(20);
   connect(_videoRetryTimer[i],&QTimer::timeout,this,[this,i](){_syncReceiver(i);});
   connect(&receivers[i],&VideoReceiver::onStartComplete,this,[this,i](VideoReceiver::STATUS s){_handleStartComplete(i,s);});
   connect(&receivers[i],&VideoReceiver::onStopComplete,this,[this,i](VideoReceiver::STATUS s){_handleStopComplete(i,s);});
  }
 }
 bool _updateSettings(unsigned id){bool changed=_videoUri[id]!=configuredUri[id];_videoUri[id]=configuredUri[id];return changed;}
 int requestedStreamMask() const; void _loadRequestedStreams(); void _saveRequestedStreams();
 Q_INVOKABLE void setVideoStreamVisible(int,bool); bool _receiverWanted(unsigned) const; void _syncReceiver(unsigned);
 void _handleStartComplete(unsigned,VideoReceiver::STATUS); void _handleStopComplete(unsigned,VideoReceiver::STATUS);
 void startVideo();void stopVideo();Q_INVOKABLE void startVideoStream(int);Q_INVOKABLE void stopVideoStream(int);
 void _startReceiver(unsigned);void _stopReceiver(unsigned);void _restartVideo(unsigned);void _initVideoSink(QQuickItem*,unsigned);
 Q_INVOKABLE void setProfileUri(int i,QString uri){configuredUri[i]=uri;_restartVideo(i);}
 void showAll(){for(int i=0;i<kStreamCount;++i)setVideoStreamVisible(i,true);}
 void startAll(){for(int i=0;i<kStreamCount;++i){setVideoStreamVisible(i,true);startVideoStream(i);receivers[i].finishStart();}}
signals:
 void requestedStreamMaskChanged();
};
#include "actual_methods.inc"
class DemandTests : public QObject {
 Q_OBJECT
 QTemporaryDir temp;
 bool applyPreset(VideoManager& m, const QString& mode) {
  QJSEngine engine;
  QQmlEngine::setObjectOwnership(&m, QQmlEngine::CppOwnership);
  engine.globalObject().setProperty("manager",engine.newQObject(&m));
  QFile file("../../xsrc/XUI/XVideoProfiles.js");
  if(!file.open(QIODevice::ReadOnly)) return false;
  if(engine.evaluate(QString::fromUtf8(file.readAll())).isError()) return false;
  auto result=engine.evaluate(QString(R"JS(
   var facts=[];
   for(var i=0;i<6;++i) (function(index){
     var fact={};Object.defineProperty(fact,'rawValue',{set:function(uri){manager.setProfileUri(index,uri);}});facts.push(fact);
   })(i);
   apply('%1',manager,facts,function(mode){var p=profile(mode);for(var i=2;i<6;++i)manager.setVideoStreamVisible(i,i<p.count);});
  )JS").arg(mode));
  return !result.isError() && result.toBool();
 }
private slots:
 void initTestCase(){QCoreApplication::setOrganizationName("UAVDemandTest");QCoreApplication::setApplicationName("isolated");QSettings::setDefaultFormat(QSettings::IniFormat);QSettings::setPath(QSettings::IniFormat,QSettings::UserScope,temp.path());}
 void init(){QSettings().clear();}
 void startupDoesNotPullHiddenStreams(){VideoManager m;m.startVideo();for(auto& r:m.receivers)QCOMPARE(r.starts,0);m.showAll();QCOMPARE(m.receivers[0].starts,1);for(int i=1;i<VideoManager::kStreamCount;++i)QCOMPARE(m.receivers[i].starts,0);}
 void fullScreenStopsOtherSubscriptionsAndRestores(){VideoManager m;m.startAll();for(int i=0;i<VideoManager::kStreamCount;++i)if(i!=2)m.setVideoStreamVisible(i,false);QCOMPARE(m.requestedStreamMask(),63);for(int i=0;i<VideoManager::kStreamCount;++i){QCOMPARE(m.receivers[i].stops,i==2?0:1);if(i!=2)m.receivers[i].finishStop();}m.showAll();for(int i=0;i<VideoManager::kStreamCount;++i)QCOMPARE(m.receivers[i].starts,i==2?1:2);}
 void closedStreamStaysClosedAfterPageRoundTrip(){VideoManager m;m.startAll();m.stopVideoStream(3);m.receivers[3].finishStop();m.setVideoStreamVisible(3,false);m.setVideoStreamVisible(3,true);m._restartVideo(3);QCOMPARE(m.receivers[3].starts,1);QCOMPARE(m.requestedStreamMask(),55);}
 void closeDuringStartRejectsLateCompletion(){VideoManager m;m.setVideoStreamVisible(0,true);m._videoSink[0]=reinterpret_cast<void*>(1);m.stopVideoStream(0);QCOMPARE(m.receivers[0].stops,1);m.receivers[0].finishStart();QCOMPARE(m.receivers[0].decodes,0);m.receivers[0].finishStop();QCOMPARE(m.receivers[0].starts,1);QVERIFY(!m._videoStarted[0]);}
 void rapidReopenWaitsForStop(){VideoManager m;m.setVideoStreamVisible(0,true);m.stopVideoStream(0);m.startVideoStream(0);QCOMPARE(m.receivers[0].starts,1);m.receivers[0].finishStart();m.receivers[0].finishStop();QCOMPARE(m.receivers[0].starts,2);QVERIFY(m._videoStarting[0]);}
 void repeatedShowAndOpenAreIdempotent(){VideoManager m;for(int j=0;j<10;++j){m.setVideoStreamVisible(0,true);m.startVideoStream(0);}QCOMPARE(m.receivers[0].starts,1);m.receivers[0].finishStart();m.startVideo();m.startVideoStream(0);QCOMPARE(m.receivers[0].starts,1);}
 void failedStartBacksOffAndHiddenCancelsRetry(){VideoManager m;m.setVideoStreamVisible(0,true);m.receivers[0].finishStart(VideoReceiver::STATUS_FAIL);QVERIFY(m._videoRetryTimer[0]->isActive());m.setVideoStreamVisible(0,false);QVERIFY(!m._videoRetryTimer[0]->isActive());QTest::qWait(35);QCOMPARE(m.receivers[0].starts,1);m.setVideoStreamVisible(0,true);QCOMPARE(m.receivers[0].starts,2);}
 void visibleNetworkFailureReconnects(){VideoManager m;m.setVideoStreamVisible(0,true);m.receivers[0].finishStart();m.receivers[0].finishStop();QVERIFY(m._videoRetryTimer[0]->isActive());QTRY_COMPARE(m.receivers[0].starts,2);}
 void stopAllPersistsChoiceButPreventsReconnect(){VideoManager m;m.startAll();m.stopVideo();for(int i=0;i<VideoManager::kStreamCount;++i)m.receivers[i].finishStop();m.showAll();for(auto& r:m.receivers)QCOMPARE(r.starts,1);QCOMPARE(m.requestedStreamMask(),63);m.startVideo();for(auto& r:m.receivers)QCOMPARE(r.starts,2);}
 void preferencesPersistIncludingAllClosed(){VideoManager m;m.startVideoStream(4);m.stopVideoStream(0);VideoManager restored;QCOMPARE(restored.requestedStreamMask(),16);restored.stopVideoStream(4);VideoManager closed;QCOMPARE(closed.requestedStreamMask(),0);closed.showAll();for(auto& r:closed.receivers)QCOMPARE(r.starts,0);}
 void urlChangedDuringStartUsesLatestAfterStop(){VideoManager m;m.setVideoStreamVisible(0,true);m.configuredUri[0]="rtsp://127.0.0.1/new";m._restartVideo(0);QCOMPARE(m.receivers[0].stops,1);m.receivers[0].finishStart();m.receivers[0].finishStop();QCOMPARE(m.receivers[0].starts,2);QCOMPARE(m.receivers[0].lastUri,m.configuredUri[0]);}
 void changingHiddenUrlDoesNotStart(){VideoManager m;m.configuredUri[0]="rtsp://127.0.0.1/new";m._restartVideo(0);QCOMPARE(m.receivers[0].starts,0);m.setVideoStreamVisible(0,true);QCOMPARE(m.receivers[0].lastUri,m.configuredUri[0]);}
 void globalDisableAndBlankUrlsDoNotPull(){VideoManager m;m.settings.enabled.setRawValue(false);m.showAll();QCOMPARE(m.receivers[0].starts,0);m.settings.enabled.setRawValue(true);m.configuredUri[0]="   ";m._restartVideo(0);QCOMPARE(m.receivers[0].starts,0);m.startVideoStream(4);QCOMPARE(m.receivers[4].starts,1);m.receivers[4].finishStart();m.settings.source.setRawValue("Disabled");m._syncReceiver(4);QCOMPARE(m.receivers[4].stops,1);m.receivers[4].finishStop();QCOMPARE(m.receivers[4].starts,1);}
 void invalidStreamIdsAreIgnored(){VideoManager m;m.setVideoStreamVisible(-1,true);m.setVideoStreamVisible(6,true);m.startVideoStream(-1);m.stopVideoStream(6);QCOMPARE(m.requestedStreamMask(),1);for(auto& r:m.receivers)QCOMPARE(r.starts,0);}
 void hiddenParentStopsChildrenWithoutLosingSelection(){
  VideoManager m;QQuickItem page;QQuickItem card(&page);
  QObject::connect(&card,&QQuickItem::visibleChanged,&m,[&](){m.setVideoStreamVisible(0,card.isVisible());});
  m.setVideoStreamVisible(0,card.isVisible());m.receivers[0].finishStart();
  page.setVisible(false);QCOMPARE(m.receivers[0].stops,1);m.receivers[0].finishStop();
  QCOMPARE(m.requestedStreamMask(),1);page.setVisible(true);QCOMPARE(m.receivers[0].starts,2);
 }
 void oldFiveStreamPreferencesDoNotEnableNewStream(){QSettings().setValue("VideoDemand/requestedStreamMask",31);VideoManager m;m.showAll();QCOMPARE(m.requestedStreamMask(),31);QCOMPARE(m.receivers[5].starts,0);}
 void gimbalInfraredChoicePersists(){VideoManager m;m.stopVideoStream(0);m.startVideoStream(5);VideoManager restored;restored.showAll();QCOMPARE(restored.requestedStreamMask(),32);QCOMPARE(restored.receivers[5].starts,1);for(int i=0;i<5;++i)QCOMPARE(restored.receivers[i].starts,0);}
 void sixthFullscreenStopsOthersAndRestores(){VideoManager m;m.startAll();for(int i=0;i<5;++i){m.setVideoStreamVisible(i,false);m.receivers[i].finishStop();}QCOMPARE(m.receivers[5].stops,0);QCOMPARE(m.requestedStreamMask(),63);m.showAll();for(int i=0;i<5;++i)QCOMPARE(m.receivers[i].starts,2);QCOMPARE(m.receivers[5].starts,1);}
 void sixthCloseDuringConnectDoesNotRestart(){VideoManager m;m.showAll();m.startVideoStream(5);m.stopVideoStream(5);m.receivers[5].finishStart();m.receivers[5].finishStop();QCOMPARE(m.receivers[5].starts,1);QCOMPARE(m.requestedStreamMask(),1);}
 void sixthHiddenRetryIsCancelled(){VideoManager m;m.setVideoStreamVisible(5,true);m.startVideoStream(5);m.receivers[5].finishStart(VideoReceiver::STATUS_FAIL);QVERIFY(m._videoRetryTimer[5]->isActive());m.setVideoStreamVisible(5,false);QTest::qWait(35);QCOMPARE(m.receivers[5].starts,1);QVERIFY(!m._videoRetryTimer[5]->isActive());}
 void gimbalPresetKeepsSharedReceiversAndReplacesPayload() {
  VideoManager m;m.startAll();auto shared0=m.configuredUri[0];auto shared1=m.configuredUri[1];
  QVERIFY(applyPreset(m,"gimbal"));
  for(int i=0;i<2;++i){QCOMPARE(m.receivers[i].stops,0);QCOMPARE(m.receivers[i].starts,1);}
  QCOMPARE(m.configuredUri[0],shared0);QCOMPARE(m.configuredUri[1],shared1);
  QCOMPARE(m.requestedStreamMask(),15);
  for(int i=2;i<6;++i)m.receivers[i].finishStop();
  QCOMPARE(m.receivers[2].lastUri,QString("rtsp://192.168.2.36:8555/gimbal"));
  QCOMPARE(m.receivers[3].lastUri,QString("rtsp://192.168.2.36:8556/gimbal_ir"));
  QCOMPARE(m.receivers[4].starts,1);QCOMPARE(m.receivers[5].starts,1);
 }
 void rapidPresetSwitchUsesLatestUrlsAfterAsyncStop() {
  VideoManager m;m.startAll();QVERIFY(applyPreset(m,"gimbal"));QVERIFY(applyPreset(m,"algorithm"));
  for(int i=2;i<6;++i)m.receivers[i].finishStop();
  QCOMPARE(m.receivers[2].lastUri,QString("rtsp://192.168.2.36:8554/algorithm"));
  QCOMPARE(m.receivers[3].lastUri,QString("rtsp://192.168.2.36:8554/preview"));
  QCOMPARE(m.receivers[4].lastUri,QString("rtsp://192.168.2.36:8554/infrared"));
  QCOMPARE(m.receivers[5].starts,1);QCOMPARE(m.requestedStreamMask(),31);
  for(int i=0;i<2;++i)QCOMPARE(m.receivers[i].stops,0);
 }
 void switchingPreservesClosedSharedCameras() {
  VideoManager m;m.stopVideoStream(0);m.showAll();QVERIFY(applyPreset(m,"algorithm"));
  QCOMPARE(m.requestedStreamMask(),28);
  for(int i=0;i<2;++i){QCOMPARE(m.receivers[i].starts,0);QCOMPARE(m.receivers[i].stops,0);}
 }
 void invalidPresetDoesNotChangeAnyStream() {
  VideoManager m;m.startAll();QVERIFY(!applyPreset(m,"invalid"));QCOMPARE(m.requestedStreamMask(),63);
  for(auto& r:m.receivers){QCOMPARE(r.starts,1);QCOMPARE(r.stops,0);}
 }
 void sinkIsReusedForSameFullscreenItem(){VideoManager m;QQuickItem item;const int before=app.box.core.creates;m._initVideoSink(&item,0);void* first=m._videoSink[0];m._initVideoSink(&item,0);QCOMPARE(app.box.core.creates,before+1);QCOMPARE(m._videoSink[0],first);}
};
QTEST_MAIN(DemandTests)
#include "demand_tests.moc"
