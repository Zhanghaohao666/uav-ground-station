"""Exercise the *packaged* Windows GStreamer DLLs, independently of Qt/GL."""
import argparse
import ctypes as c
import json
import os
from pathlib import Path


def run(package, transport):
    package = Path(package).resolve()
    dll_dir = os.add_dll_directory(str(package))
    gst = c.CDLL(str(package / "gstreamer-1.0-0.dll"))
    app = c.CDLL(str(package / "gstapp-1.0-0.dll"))
    glib = c.CDLL(str(package / "glib-2.0-0.dll"))
    ptr = c.c_void_p
    signatures = [
        (gst, "gst_init_check", [ptr, ptr, c.POINTER(ptr)], c.c_int),
        (gst, "gst_parse_launch", [c.c_char_p, c.POINTER(ptr)], ptr),
        (gst, "gst_element_set_state", [ptr, c.c_int], c.c_int),
        (gst, "gst_bin_get_by_name", [ptr, c.c_char_p], ptr),
        (gst, "gst_sample_get_caps", [ptr], ptr),
        (gst, "gst_caps_to_string", [ptr], ptr),
        (gst, "gst_mini_object_unref", [ptr], None),
        (gst, "gst_object_unref", [ptr], None),
        (app, "gst_app_sink_try_pull_sample", [ptr, c.c_uint64], ptr),
        (glib, "g_free", [ptr], None),
    ]
    for lib, name, args, result in signatures:
        function = getattr(lib, name)
        function.argtypes = args
        function.restype = result
    error = ptr()
    if not gst.gst_init_check(None, None, c.byref(error)):
        raise RuntimeError("Packaged GStreamer initialization failed")
    pipeline_text = (f"rtspsrc location=rtsp://127.0.0.1:18554/test protocols={transport} latency=17 "
                     "! rtph264depay ! h264parse ! avdec_h264 "
                     "! appsink name=decoded sync=false max-buffers=4 drop=true")
    pipeline = gst.gst_parse_launch(pipeline_text.encode(), c.byref(error))
    if not pipeline or error:
        raise RuntimeError("Packaged GStreamer could not construct H.264 decode pipeline")
    sink = gst.gst_bin_get_by_name(pipeline, b"decoded")
    caps_text = None
    try:
        if gst.gst_element_set_state(pipeline, 4) == 0:
            raise RuntimeError("Packaged GStreamer could not start decode pipeline")
        for _ in range(10):
            sample = app.gst_app_sink_try_pull_sample(sink, 5_000_000_000)
            if not sample:
                raise RuntimeError("No decoded frame within five seconds")
            try:
                caps = gst.gst_caps_to_string(gst.gst_sample_get_caps(sample))
                caps_text = c.string_at(caps).decode()
                glib.g_free(caps)
            finally:
                gst.gst_mini_object_unref(sample)
        print(json.dumps({"transport": transport, "decoded_frames": 10, "caps": caps_text}))
    finally:
        gst.gst_element_set_state(pipeline, 1)
        gst.gst_object_unref(sink)
        gst.gst_object_unref(pipeline)
        dll_dir.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("package")
    parser.add_argument("--transport", choices=["tcp", "udp"], required=True)
    args = parser.parse_args()
    run(args.package, args.transport)
