"""Loop a generated H.264 test pattern over localhost RTSP, using only Python.

This is a test fixture, not a production RTSP server. Supports interleaved TCP
and unicast UDP so the released Windows receiver can be exercised unchanged.
"""
import argparse
import base64
import re
import socket
import socketserver
import struct
import threading
import time
from pathlib import Path


class Handler(socketserver.BaseRequestHandler):
    def handle(self):
        self.lock = threading.Lock()
        self.done = threading.Event()
        self.worker = None
        self.udp = None
        self.channel = 0
        self.peer_port = None
        pending = b""
        try:
            while not self.done.is_set():
                part = self.request.recv(65536)
                if not part:
                    break
                pending += part
                while pending:
                    if pending.startswith(b"$"):
                        if len(pending) < 4:
                            break
                        length = int.from_bytes(pending[2:4], "big") + 4
                        if len(pending) < length:
                            break
                        pending = pending[length:]
                        continue
                    if b"\r\n\r\n" not in pending:
                        break
                    block, pending = pending.split(b"\r\n\r\n", 1)
                    lines = block.decode().split("\r\n")
                    method, uri, _ = lines[0].split()
                    headers = dict(line.split(":", 1) for line in lines[1:])
                    headers = {k.lower(): v.strip() for k, v in headers.items()}
                    print(method, uri, headers.get("transport", ""), flush=True)
                    reply = {"CSeq": headers.get("cseq", "1"), "Session": "12345678"}
                    body = b""
                    if method == "OPTIONS":
                        reply["Public"] = "OPTIONS, DESCRIBE, SETUP, PLAY, GET_PARAMETER, TEARDOWN"
                    elif method == "DESCRIBE":
                        reply.update({"Content-Type": "application/sdp", "Content-Base": uri.rstrip("/") + "/"})
                        body = self.server.sdp
                    elif method == "SETUP":
                        transport = headers["transport"]
                        if "TCP" in transport:
                            match = re.search(r"interleaved=(\d+)", transport)
                            self.channel = int(match[1]) if match else 0
                            reply["Transport"] = f"RTP/AVP/TCP;unicast;interleaved={self.channel}-{self.channel+1};ssrc=12345678"
                        else:
                            match = re.search(r"client_port=(\d+)-(\d+)", transport)
                            self.peer_port = int(match[1])
                            self.udp = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
                            self.udp.bind(("127.0.0.1", 0))
                            port = self.udp.getsockname()[1]
                            reply["Transport"] = f"RTP/AVP;unicast;client_port={match[1]}-{match[2]};server_port={port}-{port+1};ssrc=12345678"
                    elif method == "PLAY":
                        reply["Range"] = "npt=0.000-"
                        reply["RTP-Info"] = f"url={uri.rstrip('/')}/trackID=0;seq=0;rtptime=0"
                    reply["Content-Length"] = str(len(body))
                    packet = ("RTSP/1.0 200 OK\r\n" + "".join(f"{k}: {v}\r\n" for k, v in reply.items()) + "\r\n").encode() + body
                    with self.lock:
                        self.request.sendall(packet)
                    if method == "PLAY" and not self.worker:
                        self.worker = threading.Thread(target=self.send_frames, daemon=True)
                        self.worker.start()
                    if method == "TEARDOWN":
                        return
        except (OSError, ValueError, KeyError) as exc:
            print(type(exc).__name__, str(exc), flush=True)
        finally:
            self.done.set()
            if self.worker:
                self.worker.join(2)
            if self.udp:
                self.udp.close()

    def send_frames(self):
        seq = 0
        frame = 0
        try:
            while not self.done.is_set():
                start = time.monotonic()
                access_unit = self.server.frames[frame % len(self.server.frames)]
                for nal_index, nal in enumerate(access_unit):
                    payloads = [nal]
                    if len(nal) > 1200:
                        chunks = [nal[i:i+1198] for i in range(1, len(nal), 1198)]
                        payloads = [bytes([(nal[0] & 0xe0) | 28, (nal[0] & 31) | (0x80 if i == 0 else 0) | (0x40 if i == len(chunks)-1 else 0)]) + chunk for i, chunk in enumerate(chunks)]
                    for i, payload in enumerate(payloads):
                        marker = nal_index == len(access_unit)-1 and i == len(payloads)-1
                        packet = struct.pack("!BBHII", 0x80, 96 | (128 if marker else 0), seq % 65536, (frame * 9000) % (2**32), 0x12345678) + payload
                        if self.udp:
                            self.udp.sendto(packet, (self.client_address[0], self.peer_port))
                        else:
                            with self.lock:
                                self.request.sendall(b"$" + bytes([self.channel]) + struct.pack("!H", len(packet)) + packet)
                        seq += 1
                frame += 1
                self.done.wait(max(0, 0.1 - (time.monotonic() - start)))
        except OSError:
            self.done.set()


def serve(port, fixture):
    nals = [x for x in re.split(b"\x00\x00\x00?\x01", Path(fixture).read_bytes()) if x]
    frames = []
    for nal in nals:
        if nal[0] & 31 == 9:
            frames.append([])
        if frames:
            frames[-1].append(nal)
    sps = next(x for x in nals if x[0] & 31 == 7)
    pps = next(x for x in nals if x[0] & 31 == 8)
    sdp = f"v=0\r\no=- 1 1 IN IP4 127.0.0.1\r\ns=Windows video regression fixture\r\nc=IN IP4 127.0.0.1\r\nt=0 0\r\na=control:*\r\nm=video 0 RTP/AVP 96\r\na=rtpmap:96 H264/90000\r\na=fmtp:96 packetization-mode=1;profile-level-id={sps[1:4].hex()};sprop-parameter-sets={base64.b64encode(sps).decode()},{base64.b64encode(pps).decode()}\r\na=control:trackID=0\r\n".encode()
    with socketserver.ThreadingTCPServer(("127.0.0.1", port), Handler) as server:
        server.daemon_threads = True
        server.frames = frames
        server.sdp = sdp
        print(f"READY rtsp://127.0.0.1:{port}/test ({len(frames)} frames)", flush=True)
        server.serve_forever()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=18554)
    parser.add_argument("--fixture", default=str(Path(__file__).with_name("test-pattern.h264")))
    args = parser.parse_args()
    serve(args.port, args.fixture)
