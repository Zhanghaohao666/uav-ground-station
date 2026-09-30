import socket
import json
import time

HOST = "0.0.0.0"
PORT = 8890

def send_json(conn, obj):
    data = json.dumps(obj, ensure_ascii=False) + "\n"
    conn.sendall(data.encode("utf-8"))
    print("SEND:", data.strip())

with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as server:
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind((HOST, PORT))
    server.listen(1)

    print(f"TCP JSON mock server listening on {HOST}:{PORT}")

    while True:
        conn, addr = server.accept()
        print("CLIENT CONNECTED:", addr)

        try:
            with conn:
                buffer = b""
                while True:
                    data = conn.recv(4096)
                    if not data:
                        print("CLIENT DISCONNECTED")
                        break

                    buffer += data

                    while b"\n" in buffer:
                        line, buffer = buffer.split(b"\n", 1)
                        line = line.strip()
                        if not line:
                            continue

                        text = line.decode("utf-8", errors="ignore")
                        print("RECV:", text)

                        try:
                            req = json.loads(text)
                        except Exception as e:
                            send_json(conn, {
                                "task_id": "",
                                "status": "failed",
                                "progress": 0,
                                "msg": f"JSON parse error: {e}"
                            })
                            continue

                        task_id = req.get("task_id", "")
                        command = req.get("command", "")

                        if command == "start_script":
                            send_json(conn, {
                                "task_id": task_id,
                                "status": "running",
                                "progress": 10,
                                "msg": "脚本已启动"
                            })

                            time.sleep(2)
                            send_json(conn, {
                                "task_id": task_id,
                                "status": "running",
                                "progress": 60,
                                "msg": "脚本执行中"
                            })

                            time.sleep(2)
                            send_json(conn, {
                                "task_id": task_id,
                                "status": "success",
                                "progress": 100,
                                "msg": "脚本执行完成"
                            })
                        else:
                            send_json(conn, {
                                "task_id": task_id,
                                "status": "failed",
                                "progress": 0,
                                "msg": f"unknown command: {command}"
                            })

        except Exception as e:
            print("ERROR:", e)