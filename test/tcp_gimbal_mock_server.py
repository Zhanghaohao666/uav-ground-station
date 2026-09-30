import argparse
import socket
import struct
import threading
import time


MAGIC = 0xAA

CMD_TRACK_XY = 0x01
CMD_TRACK_ID = 0x02
CMD_TRACK_UNLOCK = 0x03
CMD_TRACK_BOX = 0x04
CMD_DETECTION_CONTROL = 0x05
CMD_GIMBAL_CENTER = 0x10
CMD_GIMBAL_DOWN90 = 0x11
CMD_GIMBAL_SET_ANGLE = 0x12
CMD_GIMBAL_SPEED = 0x13
CMD_GIMBAL_LOCK = 0x14
CMD_STATUS_REPORT = 0x80
CMD_TARGET_LIST = 0x81

TRACKER_WAIT = 1
TRACKER_SEARCH = 2
TRACKER_TRACK = 3
TRACKER_RECAP = 4
TRACKER_LOST = 5

COMMAND_NAMES = {
    CMD_TRACK_XY: "TRACK_XY",
    CMD_TRACK_ID: "TRACK_ID",
    CMD_TRACK_UNLOCK: "TRACK_UNLOCK",
    CMD_TRACK_BOX: "TRACK_BOX",
    CMD_DETECTION_CONTROL: "DETECTION_CONTROL",
    CMD_GIMBAL_CENTER: "GIMBAL_CENTER",
    CMD_GIMBAL_DOWN90: "GIMBAL_DOWN90",
    CMD_GIMBAL_SET_ANGLE: "GIMBAL_SET_ANGLE",
    CMD_GIMBAL_SPEED: "GIMBAL_SPEED",
    CMD_GIMBAL_LOCK: "GIMBAL_LOCK",
}

STATUS_NAMES = {
    TRACKER_WAIT: "WAIT",
    TRACKER_SEARCH: "SEARCH",
    TRACKER_TRACK: "TRACK",
    TRACKER_RECAP: "RECAP",
    TRACKER_LOST: "LOST",
}


def make_frame(command_id, payload=b""):
    return struct.pack("<BBH", MAGIC, command_id, len(payload)) + payload


def send_frame(conn, command_id, payload=b"", split=False):
    frame = make_frame(command_id, payload)
    if split and len(frame) > 3:
        conn.sendall(frame[:3])
        time.sleep(0.05)
        conn.sendall(frame[3:])
    else:
        conn.sendall(frame)
    print(f"SEND 0x{command_id:02X} len={len(payload)} payload={payload.hex(' ')}")


def make_status_payload(step):
    status_cycle = [
        TRACKER_WAIT,
        TRACKER_SEARCH,
        TRACKER_TRACK,
        TRACKER_TRACK,
        TRACKER_RECAP,
        TRACKER_LOST,
        TRACKER_TRACK,
    ]
    tracker_status = status_cycle[step % len(status_cycle)]

    if tracker_status == TRACKER_TRACK:
        track_x = 320 + (step * 17) % 500
        track_y = 180 + (step * 9) % 300
        track_w = 120
        track_h = 80
    else:
        track_x = 0
        track_y = 0
        track_w = 0
        track_h = 0

    yaw_centideg = int((-15.0 + (step % 30)) * 100)
    pitch_centideg = int((-45.0 + (step % 20) * 0.5) * 100)
    target_count = 3

    return struct.pack(
        "<BhhhhhhB",
        tracker_status,
        track_x,
        track_y,
        track_w,
        track_h,
        yaw_centideg,
        pitch_centideg,
        target_count,
    )


def make_target_list_payload(step):
    targets = [
        (300 + (step * 7) % 120, 210, 110, 80, 1001),
        (760, 380 + (step * 5) % 90, 130, 90, 1002),
        (1180, 520, 160, 100, 1003),
    ]

    payload = struct.pack("<B", len(targets))
    for target in targets:
        payload += struct.pack("<hhhhi", *target)
    return payload


def describe_command(command_id, payload):
    try:
        if command_id == CMD_TRACK_XY and len(payload) == 4:
            x, y = struct.unpack("<hh", payload)
            return f"TRACK_XY x={x} y={y}"
        if command_id == CMD_TRACK_ID and len(payload) == 4:
            target_id, = struct.unpack("<i", payload)
            return f"TRACK_ID id={target_id}"
        if command_id == CMD_TRACK_UNLOCK and len(payload) == 0:
            return "TRACK_UNLOCK"
        if command_id == CMD_TRACK_BOX and len(payload) == 8:
            x, y, width, height = struct.unpack("<hhhh", payload)
            return f"TRACK_BOX x={x} y={y} w={width} h={height}"
        if command_id == CMD_DETECTION_CONTROL and len(payload) == 1:
            enabled, = struct.unpack("<B", payload)
            return f"DETECTION_CONTROL enabled={enabled}"
        if command_id == CMD_GIMBAL_CENTER and len(payload) == 0:
            return "GIMBAL_CENTER"
        if command_id == CMD_GIMBAL_DOWN90 and len(payload) == 0:
            return "GIMBAL_DOWN90"
        if command_id == CMD_GIMBAL_SET_ANGLE and len(payload) == 4:
            pitch, yaw = struct.unpack("<hh", payload)
            return f"GIMBAL_SET_ANGLE pitch={pitch} yaw={yaw}"
        if command_id == CMD_GIMBAL_SPEED and len(payload) == 2:
            yaw_speed, pitch_speed = struct.unpack("<BB", payload)
            return f"GIMBAL_SPEED yaw_speed={yaw_speed} pitch_speed={pitch_speed}"
        if command_id == CMD_GIMBAL_LOCK and len(payload) == 1:
            mode, = struct.unpack("<B", payload)
            return f"GIMBAL_LOCK mode={mode}"
    except struct.error as exc:
        return f"parse error: {exc}"

    name = COMMAND_NAMES.get(command_id, "UNKNOWN")
    return f"{name} raw={payload.hex(' ')}"


def receive_loop(conn, stop_event):
    buffer = b""
    while not stop_event.is_set():
        data = conn.recv(4096)
        if not data:
            stop_event.set()
            break

        buffer += data
        while len(buffer) >= 4:
            if buffer[0] != MAGIC:
                dropped = buffer[0]
                buffer = buffer[1:]
                print(f"DROP 0x{dropped:02X} while resyncing")
                continue

            command_id = buffer[1]
            payload_len = buffer[2] | (buffer[3] << 8)
            if len(buffer) < 4 + payload_len:
                break

            payload = buffer[4:4 + payload_len]
            buffer = buffer[4 + payload_len:]
            print(
                f"RECV 0x{command_id:02X} len={payload_len} "
                f"{describe_command(command_id, payload)}"
            )


def report_loop(conn, stop_event, interval, split_frames, send_garbage):
    step = 0
    if send_garbage:
        conn.sendall(b"\x00\x55\x12")
        print("SEND leading garbage: 00 55 12")

    while not stop_event.is_set():
        try:
            status_payload = make_status_payload(step)
            send_frame(conn, CMD_STATUS_REPORT, status_payload, split=split_frames)

            if step % 3 == 0:
                send_frame(conn, CMD_TARGET_LIST, make_target_list_payload(step), split=False)

            step += 1
            time.sleep(interval)
        except (BrokenPipeError, ConnectionResetError, OSError):
            stop_event.set()
            break


def run_server(host, port, interval, split_frames, send_garbage):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as server:
        server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        server.bind((host, port))
        server.listen(1)
        print(f"TCP gimbal mock server listening on {host}:{port}")
        print("Use the ground station Pod page command channel to connect.")

        while True:
            conn, addr = server.accept()
            print(f"CLIENT CONNECTED {addr}")
            stop_event = threading.Event()

            with conn:
                reporter = threading.Thread(
                    target=report_loop,
                    args=(conn, stop_event, interval, split_frames, send_garbage),
                    daemon=True,
                )
                reporter.start()
                try:
                    receive_loop(conn, stop_event)
                except (ConnectionResetError, OSError) as exc:
                    print(f"CLIENT ERROR {exc}")
                finally:
                    stop_event.set()
                    reporter.join(timeout=1.0)
                    print("CLIENT DISCONNECTED")


def main():
    parser = argparse.ArgumentParser(description="Mock server for the gimbal TCP binary protocol.")
    parser.add_argument("--host", default="127.0.0.1", help="Listen address, default: 127.0.0.1")
    parser.add_argument("--port", type=int, default=9000, help="Listen port, default: 9000")
    parser.add_argument("--interval", type=float, default=1.0, help="Status report interval seconds")
    parser.add_argument("--split", action="store_true", help="Split status frames to test client reassembly")
    parser.add_argument("--garbage", action="store_true", help="Send leading garbage to test client resync")
    args = parser.parse_args()

    run_server(args.host, args.port, args.interval, args.split, args.garbage)


if __name__ == "__main__":
    main()
