#pragma once

#include <gst/gst.h>

/* Keep radio jitter handling separate from decoded-frame display buffering. */
#define UAV_RTSP_JITTER_MS 120u
#define UAV_DECODED_QUEUE_BUFFERS 2u

static inline void uav_configure_rtsp_source(GstElement* source)
{
    g_object_set(source, "latency", UAV_RTSP_JITTER_MS,
                 "drop-on-latency", TRUE,
                 "udp-buffer-size", 2 * 1024 * 1024, NULL);
}

static inline void uav_configure_decoded_queue(GstElement* queue)
{
    /* This queue must only receive decoded raw video, never H.264/H.265. */
    g_object_set(queue, "max-size-buffers", UAV_DECODED_QUEUE_BUFFERS,
                 "max-size-bytes", 0u, "max-size-time", (guint64)0,
                 "leaky", 2, "silent", TRUE, NULL);
}

static inline void uav_configure_display_sink(GstElement* sink)
{
    g_object_set(sink, "qos", TRUE,
                 "max-lateness", (gint64)(100 * GST_MSECOND), NULL);
}
