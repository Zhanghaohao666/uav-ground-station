#include <QtTest>
#include <atomic>
#include <gst/app/gstappsrc.h>
#include <gst/app/gstappsink.h>
#include "GstVideoReceiver.h"
#include "VideoPlaybackPolicy.h"

class ProbeReceiver : public GstVideoReceiver {
public:
    int transport = 0;
    ProbeReceiver() { _buffer = 0; }
    GstElement* source(const QString& uri) { return _makeSource(uri); }
protected:
    GstElement* _makeSource(const QString& uri) override {
        GstElement* bin = GstVideoReceiver::_makeSource(uri);
        if (bin && transport) {
            GstElement* source = gst_bin_get_by_name(GST_BIN(bin), "source");
            if (source) { g_object_set(source, "protocols", transport, nullptr); gst_object_unref(source); }
        }
        return bin;
    }
};

class ReceiverTests : public QObject {
    Q_OBJECT
private slots:
    void initTestCase() {
        gst_init(nullptr, nullptr);
        qRegisterMetaType<VideoReceiver::STATUS>();
        // Headless decoder checks deliberately use libav rather than a GPU.
        GstPluginFeature* decoder = gst_registry_find_feature(gst_registry_get(), "avdec_h264", GST_TYPE_ELEMENT_FACTORY);
        QVERIFY(decoder);
        gst_plugin_feature_set_rank(decoder, 512);
        gst_object_unref(decoder);
    }
    void realReceiverUsesRadioJitterPolicy() {
        ProbeReceiver receiver;
        GstElement* bin = receiver.source("rtsp://127.0.0.1:18554/test");
        QVERIFY(bin);
        GstElement* source = gst_bin_get_by_name(GST_BIN(bin), "source");
        QVERIFY(source);
        guint latency = 0;
        gboolean drop = FALSE;
        gint bytes = 0;
        g_object_get(source, "latency", &latency, "drop-on-latency", &drop, "udp-buffer-size", &bytes, nullptr);
        QCOMPARE(latency, 120u);QVERIFY(drop);QCOMPARE(bytes, 2 * 1024 * 1024);
        gst_object_unref(source);gst_object_unref(bin);
    }
    void decodedDisplayQueueKeepsRecentFramesWhenConsumerStalls() {
        GError* error = nullptr;
        GstElement* pipeline = gst_parse_launch(
            "appsrc name=input is-live=true format=time caps=video/x-raw,format=RGB,width=16,height=16,framerate=30/1 "
            "! queue name=display ! appsink name=output sync=false max-buffers=1 drop=false", &error);
        QVERIFY2(pipeline && !error, error ? error->message : "pipeline missing");
        GstElement* input = gst_bin_get_by_name(GST_BIN(pipeline), "input");
        GstElement* display = gst_bin_get_by_name(GST_BIN(pipeline), "display");
        GstElement* output = gst_bin_get_by_name(GST_BIN(pipeline), "output");
        uav_configure_decoded_queue(display);
        QVERIFY(gst_element_set_state(pipeline, GST_STATE_PLAYING) != GST_STATE_CHANGE_FAILURE);
        for (int i = 0; i < 30; ++i) {
            GstBuffer* buffer = gst_buffer_new_allocate(nullptr, 16 * 16 * 3, nullptr);
            GST_BUFFER_PTS(buffer) = i * GST_MSECOND;
            GST_BUFFER_DURATION(buffer) = GST_MSECOND;
            QCOMPARE(gst_app_src_push_buffer(GST_APP_SRC(input), buffer), GST_FLOW_OK);
        }
        QTest::qWait(100);
        guint queued = 0;g_object_get(display, "current-level-buffers", &queued, nullptr);
        QVERIFY(queued <= 2u);
        GstClockTime last = 0;
        for (int i = 0; i < 5; ++i) {
            GstSample* sample = gst_app_sink_try_pull_sample(GST_APP_SINK(output), 200 * GST_MSECOND);
            if (!sample) break;
            last = GST_BUFFER_PTS(gst_sample_get_buffer(sample));gst_sample_unref(sample);
        }
        QVERIFY2(last >= 28 * GST_MSECOND, "display drained old frames instead of the newest decoded frames");
        gst_element_set_state(pipeline, GST_STATE_NULL);
        gst_object_unref(input);gst_object_unref(display);gst_object_unref(output);gst_object_unref(pipeline);
    }
    void actualReceiverDecodesTcpAndUdp_data() {
        QTest::addColumn<int>("transport");QTest::newRow("tcp") << 4;QTest::newRow("udp") << 1;
    }
    void actualReceiverDecodesTcpAndUdp() {
        const QString uri = qEnvironmentVariable("UAV_TEST_RTSP_URL");
        if (uri.isEmpty()) QSKIP("Requires localhost generated RTSP fixture");
        QFETCH(int, transport);
        GstElement* sink = gst_element_factory_make("fakesink", nullptr);QVERIFY(sink);
        gst_object_ref_sink(sink);
        std::atomic<int> frames{0};
        g_object_set(sink, "signal-handoffs", TRUE, nullptr);
        uav_configure_display_sink(sink);
        g_signal_connect(sink, "handoff", G_CALLBACK(+[](GstElement*, GstBuffer*, GstPad*, gpointer data) {
            static_cast<std::atomic<int>*>(data)->fetch_add(1);
        }), &frames);
        {
            ProbeReceiver receiver;receiver.transport = transport;
            QSignalSpy streaming(&receiver, &VideoReceiver::streamingChanged);
            QSignalSpy sizes(&receiver, &VideoReceiver::videoSizeChanged);
            receiver.start(uri, 5, 0);receiver.startDecoding(sink);
            QTRY_VERIFY_WITH_TIMEOUT(frames.load() >= 10, 10000);
            QVERIFY(!sizes.isEmpty());QCOMPARE(sizes.last().at(0).toSize(), QSize(320, 240));
            receiver.stop();
        }
        gst_object_unref(sink);
    }
};
QTEST_GUILESS_MAIN(ReceiverTests)
#include "receiver_tests.moc"
