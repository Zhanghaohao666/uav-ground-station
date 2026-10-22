#!/usr/bin/env python3
"""Offline administrator tool. NEVER distribute the private key to customers."""
import argparse
import base64
import datetime as dt
import getpass
import hashlib
import json
import os
from pathlib import Path
import re
import sys
import uuid

from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding, rsa

PRODUCT = "NexusGround"
MACHINE_RE = re.compile(r"NGL1(?:-[A-F0-9]{8}){8}\Z")
UTC = dt.timezone.utc


def key_id(public_key):
    der = public_key.public_bytes(serialization.Encoding.DER, serialization.PublicFormat.SubjectPublicKeyInfo)
    return hashlib.sha256(der).hexdigest()[:24]


def load_key(path, password=None):
    raw = Path(path).read_bytes()
    key = serialization.load_pem_private_key(raw, password=password)
    if not isinstance(key, rsa.RSAPrivateKey) or key.key_size != 3072 or key.public_key().public_numbers().e != 65537:
        raise ValueError("需要 RSA-3072、指数 65537 的私钥")
    return key


def public_header(key):
    public = key.public_key()
    pem = public.public_bytes(serialization.Encoding.PEM, serialization.PublicFormat.SubjectPublicKeyInfo).decode("ascii")
    modulus = public.public_numbers().n.to_bytes(384, "big").hex()
    return ("// Public verification key only. The private key must remain outside the repository.\n"
            "#pragma once\nnamespace NexusLicenseKey {\n"
            f'constexpr char id[] = "{key_id(public)}";\n'
            f'constexpr char modulus[] = "{modulus}";\n'
            f'constexpr char pem[] = R"NGLKEY({pem})NGLKEY";\n}}\n')


def initialize(private_path, header_path, password=None):
    private_path, header_path = Path(private_path).resolve(), Path(header_path).resolve()
    repo = Path(__file__).resolve().parents[2]
    if (repo / ".git").exists() and (private_path == repo or repo in private_path.parents):
        raise ValueError("私钥必须保存在源码仓库之外")
    if private_path.exists():
        raise ValueError("私钥已存在；为避免旧授权失效，禁止覆盖。使用 export-public 导出已有密钥。")
    if header_path.exists():
        raise ValueError("公钥头文件已存在；禁止意外轮换生产密钥。")
    key = rsa.generate_private_key(public_exponent=65537, key_size=3072)
    encryption = serialization.BestAvailableEncryption(password) if password else serialization.NoEncryption()
    raw = key.private_bytes(serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8, encryption)
    private_path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    fd = os.open(str(private_path), os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
    with os.fdopen(fd, "wb") as stream:
        stream.write(raw)
    header_path.parent.mkdir(parents=True, exist_ok=True)
    header_path.write_text(public_header(key), encoding="utf-8")
    return key_id(key.public_key())


def read_request(path):
    with Path(path).open("rb") as stream:
        raw = stream.read(65537)
    if len(raw) > 65536:
        raise ValueError("申请文件过大")
    data = json.loads(raw.decode("utf-8-sig"))
    if (not isinstance(data, dict) or data.get("schema") != 1 or data.get("product") != PRODUCT
            or not MACHINE_RE.fullmatch(data.get("machine", ""))):
        raise ValueError("无效的 NexusGround 授权申请")
    if not re.fullmatch(r"[a-f0-9]{24}", data.get("key_id", "")):
        raise ValueError("申请缺少有效的签发密钥编号")
    return data


def stamp(value):
    return value.astimezone(UTC).replace(microsecond=0).strftime("%Y-%m-%dT%H:%M:%SZ")


def issue(key, machine, customer, expires=None, now=None, request_key_id=None):
    machine = machine.strip().upper()
    if not MACHINE_RE.fullmatch(machine):
        raise ValueError("机器码格式错误，请完整复制 NGL1 开头的机器码")
    customer = customer.strip()
    if not customer or len(customer) > 200:
        raise ValueError("请填写 1～200 字的授权对象")
    identifier = key_id(key.public_key())
    if request_key_id and request_key_id != identifier:
        raise ValueError("申请的密钥编号与所选私钥不匹配，请选择这版地面站对应的私钥")
    now = (now or dt.datetime.now(UTC)).replace(microsecond=0)
    if expires is not None and (expires.tzinfo is None or expires <= now):
        raise ValueError("到期时间必须晚于当前时间并含时区")
    payload = {
        "schema": 1, "product": PRODUCT, "machine": machine,
        "customer": customer, "license_id": str(uuid.uuid4()),
        "issued_at": stamp(now), "not_before": stamp(now - dt.timedelta(minutes=5)),
        "expires_at": stamp(expires) if expires else None,
        "features": ["ground-station"],
    }
    message = json.dumps(payload, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode("utf-8")
    signature = key.sign(message, padding.PSS(mgf=padding.MGF1(hashes.SHA256()), salt_length=32), hashes.SHA256())
    return {"format": "NGLIC-1", "algorithm": "RSA-PSS-SHA256", "key_id": identifier,
            "payload": base64.b64encode(message).decode("ascii"),
            "signature": base64.b64encode(signature).decode("ascii")}


def write_license(path, envelope):
    # Never overwrite an earlier customer license or a private key by accident.
    with Path(path).open("x", encoding="utf-8") as stream:
        json.dump(envelope, stream, ensure_ascii=False, indent=2)
        stream.write("\n")


def activation_code(envelope):
    """ASCII copy/paste transport; retain exact signed bytes and production key."""
    if (not isinstance(envelope, dict) or envelope.get("format") != "NGLIC-1"
            or envelope.get("algorithm") != "RSA-PSS-SHA256"
            or not re.fullmatch(r"[a-f0-9]{24}", envelope.get("key_id", ""))):
        raise ValueError("无效的签名授权内容")
    parts = ["NGAC1", envelope["key_id"]]
    for name in ("payload", "signature"):
        value = base64.b64decode(envelope[name], validate=True)
        if not value or (name == "signature" and len(value) != 384):
            raise ValueError("无效的授权签名")
        parts.append(base64.urlsafe_b64encode(value).decode("ascii").rstrip("="))
    code = ".".join(parts)
    if len(code) > 16384:
        raise ValueError("激活码过长")
    return code


def expiration_date(text):
    if not text.strip():
        return None
    day = dt.datetime.strptime(text.strip(), "%Y-%m-%d").date()
    # A date means valid through that date in China, exclusive midnight after it.
    china = dt.timezone(dt.timedelta(hours=8))
    return dt.datetime.combine(day + dt.timedelta(days=1), dt.time(), tzinfo=china).astimezone(UTC)


def gui():
    import tkinter as tk
    from tkinter import filedialog, messagebox, ttk
    root = tk.Tk()
    root.title("NexusGround 管理员激活码签发工具")
    root.geometry("840x530")
    root.minsize(750, 480)
    frame = ttk.Frame(root, padding=15)
    frame.pack(fill="both", expand=True)
    fields = {}
    labels = [("machine", "客户机器码"), ("customer", "授权对象"),
              ("expires", "到期日期（留空为永久）"), ("key", "管理员私钥"),
              ("password", "私钥密码（未加密则留空）")]
    ttk.Label(frame, text="粘贴客户发来的 NGL1- 机器码，生成激活码后复制发给对方即可。").grid(
        row=0, column=0, columnspan=3, pady=(0, 15), sticky="w")
    for row, (name, label) in enumerate(labels, 1):
        ttk.Label(frame, text=label).grid(row=row, column=0, padx=(0, 10), pady=8, sticky="w")
        fields[name] = tk.StringVar()
        ttk.Entry(frame, textvariable=fields[name], width=60, show="*" if name == "password" else "").grid(
            row=row, column=1, columnspan=1 if name in ("key", "machine") else 2, sticky="ew")
    fields["customer"].set("授权用户")
    def paste_machine():
        try:
            fields["machine"].set(root.clipboard_get().strip())
        except tk.TclError:
            messagebox.showerror("无法粘贴", "剪贴板中没有文字，请先复制客户的完整机器码。")
    ttk.Button(frame, text="粘贴机器码", command=paste_machine).grid(row=1, column=2, padx=(8, 0))
    def pick_key():
        path = filedialog.askopenfilename(title="选择管理员私钥", filetypes=[("私钥", "*.pem"), ("所有文件", "*")])
        if path:
            fields["key"].set(path)
    ttk.Button(frame, text="选择", command=pick_key).grid(row=4, column=2, padx=(8, 0))
    frame.columnconfigure(1, weight=1)
    frame.rowconfigure(8, weight=1)
    default_key = Path(sys.executable if getattr(sys, "frozen", False) else __file__).resolve().parent / "owner-key.private.pem"
    if default_key.exists():
        fields["key"].set(str(default_key))
    status = tk.StringVar(value="激活码只适用于对应电脑；到期日期格式为 YYYY-MM-DD。")
    ttk.Label(frame, textvariable=status, wraplength=780).grid(row=6, column=0, columnspan=3, sticky="w", pady=10)
    ttk.Label(frame, text="生成的激活码（完整复制发给客户）").grid(row=7, column=0, columnspan=3, sticky="w")
    output = tk.Text(frame, height=7, wrap="char", state="disabled")
    output.grid(row=8, column=0, columnspan=3, sticky="nsew", pady=8)
    current_code = [""]
    def set_output(code):
        current_code[0] = code
        output.configure(state="normal")
        output.delete("1.0", "end")
        output.insert("1.0", code)
        output.configure(state="disabled")
        copy_button.configure(state="normal" if code else "disabled")
    def changed(*_):
        set_output("")
        status.set("参数已改变，请重新生成激活码。")
    def sign():
        set_output("")
        try:
            password = fields["password"].get().encode("utf-8") or None
            key = load_key(fields["key"].get(), password)
            envelope = issue(key, fields["machine"].get(), fields["customer"].get(),
                             expiration_date(fields["expires"].get()))
            set_output(activation_code(envelope))
            status.set("激活码已生成，点击“复制激活码”后发给客户。")
        except Exception as error:
            status.set("签发失败，请检查输入。")
            messagebox.showerror("签发失败", str(error))
    def copy_code():
        if current_code[0]:
            root.clipboard_clear()
            root.clipboard_append(current_code[0])
            status.set("激活码已复制，只把这段激活码发给客户即可。")
    buttons = ttk.Frame(frame)
    buttons.grid(row=9, column=0, columnspan=3, pady=8)
    ttk.Button(buttons, text="生成激活码", command=sign).pack(side="left", padx=8)
    copy_button = ttk.Button(buttons, text="复制激活码", command=copy_code, state="disabled")
    copy_button.pack(side="left", padx=8)
    for variable in fields.values():
        variable.trace_add("write", changed)
    ttk.Label(frame, text="仅供管理员使用，不能把本工具和私钥发给客户。").grid(row=10, column=0, columnspan=3, pady=(8, 0), sticky="w")
    root.mainloop()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command")
    init = sub.add_parser("init", help="首次创建私钥及编译用公钥，禁止覆盖已有密钥")
    init.add_argument("--private-key", required=True)
    init.add_argument("--public-header", required=True)
    init.add_argument("--encrypt", action="store_true")
    export = sub.add_parser("export-public")
    export.add_argument("--private-key", required=True)
    export.add_argument("--public-header", required=True)
    export.add_argument("--ask-password", action="store_true")
    sign = sub.add_parser("issue")
    sign.add_argument("--private-key", required=True)
    source = sign.add_mutually_exclusive_group(required=True)
    source.add_argument("--request")
    source.add_argument("--machine")
    sign.add_argument("--customer", required=True)
    sign.add_argument("--expires", default="", help="中国时区日期，含当天；不填为永久")
    output = sign.add_mutually_exclusive_group(required=True)
    output.add_argument("--out", help="兼容旧版：保存授权文件")
    output.add_argument("--code", action="store_true", help="直接输出可粘贴激活码，无需交换文件")
    sign.add_argument("--ask-password", action="store_true")
    sub.add_parser("gui")
    args = parser.parse_args()
    if args.command in (None, "gui"):
        gui()
    elif args.command == "init":
        password = getpass.getpass("新私钥密码：").encode("utf-8") if args.encrypt else None
        if args.encrypt and not password:
            raise ValueError("密码不能为空")
        print("公钥编号：" + initialize(args.private_key, args.public_header, password))
    else:
        password = getpass.getpass("私钥密码：").encode("utf-8") if args.ask_password else None
        key = load_key(args.private_key, password)
        if args.command == "export-public":
            Path(args.public_header).write_text(public_header(key), encoding="utf-8")
            print("公钥编号：" + key_id(key.public_key()))
        else:
            request = read_request(args.request) if args.request else None
            envelope = issue(key, request["machine"] if request else args.machine, args.customer,
                             expiration_date(args.expires), request_key_id=request["key_id"] if request else None)
            if args.code:
                print(activation_code(envelope))
            else:
                write_license(args.out, envelope)
                print("授权文件已生成：" + args.out)


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print("错误：" + str(error), file=sys.stderr)
        sys.exit(1)
