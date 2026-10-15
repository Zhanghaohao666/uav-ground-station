The RTSP fixture serves the generated, non-camera `test-pattern.h264` on
127.0.0.1 only. It supports the TCP and UDP modes used by GStreamer rtspsrc.
It is not suitable for deployment on a board or a public interface.

Regenerate the fixture with FFmpeg (libx264):

```sh
ffmpeg -f lavfi -i testsrc2=size=320x240:rate=10 -t 2 \
  -c:v libx264 -preset ultrafast -tune zerolatency -pix_fmt yuv420p \
  -x264-params aud=1:repeat-headers=1:keyint=10 -f h264 test-pattern.h264
```

`tools/windows/repro-video.ps1` runs the actual application with this stream
under three OpenGL choices and saves receiver and GStreamer logs. The script
resets the hosted runner's NexusGround registry settings; run it only in CI.
The released-video workflow first checks the original release archive's hash.
These checks do not replace a Windows/MK22 field test.
