#!/bin/bash
set -eu
# Run on the main RK3588 as root, after copying this directory to:
# /home/dev/uav_autostart/gimbal_ir_20260929
stage=/home/dev/uav_autostart/gimbal_ir_20260929
cd "$stage"
python3 - <<'BUILD'
import shlex,subprocess
flags=shlex.split(subprocess.check_output(['pkg-config','--cflags','--libs','gstreamer-rtsp-server-1.0']).decode())
subprocess.run(['gcc','-O2','-Wall','-Wextra','rtsp_relay_gimbal.c','-o','rtsp_relay_gimbal']+flags,check=True)
BUILD
install -m 644 units/uav-gimbal-ir-ingest.service /etc/systemd/system/
install -m 644 units/uav-gimbal-ir-rtsp.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable uav-gimbal-ir-ingest.service uav-gimbal-ir-rtsp.service
systemctl restart uav-gimbal-ir-rtsp.service uav-gimbal-ir-ingest.service
