"""Exercise the actual administrator GUI with a disposable private key only."""
import base64
import importlib.util
from pathlib import Path
import tempfile
import tkinter as tk
from tkinter import messagebox
from unittest import mock

spec = importlib.util.spec_from_file_location("authority", Path(__file__).resolve().parents[2] / "tools/licensing/license_authority.py")
a = importlib.util.module_from_spec(spec)
spec.loader.exec_module(a)
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import padding


def check_gui(root):
    try:
        frame = root.winfo_children()[0]
        entries = {int(w.grid_info()["row"]): w for w in frame.winfo_children() if w.winfo_class() == "TEntry"}
        widgets = []
        def visit(parent):
            for w in parent.winfo_children():
                widgets.append(w)
                visit(w)
        visit(root)
        buttons = {w.cget("text"): w for w in widgets if w.winfo_class() == "TButton"}
        output = next(w for w in widgets if w.winfo_class() == "Text")
        def fill(row, text):
            entries[row].delete(0, "end")
            entries[row].insert(0, text)
        machine = "NGL1" + "-A1B2C3D4" * 8
        with tempfile.TemporaryDirectory() as temp:
            private = Path(temp) / "owner.private.pem"
            a.initialize(private, Path(temp) / "public.h")
            fill(4, str(private))
            root.clipboard_clear()
            root.clipboard_append(machine)
            buttons["粘贴机器码"].invoke()
            assert entries[1].get() == machine
            fill(2, "GUI测试")
            with mock.patch.object(messagebox, "showerror") as error:
                buttons["生成激活码"].invoke()
                error.assert_not_called()
                code = output.get("1.0", "end-1c")
                prefix, identifier, payload, signature = code.split(".")
                assert prefix == "NGAC1"
                decode = lambda v: base64.urlsafe_b64decode(v + "=" * (-len(v) % 4))
                key = a.load_key(private)
                assert identifier == a.key_id(key.public_key())
                key.public_key().verify(decode(signature), decode(payload),
                    padding.PSS(mgf=padding.MGF1(hashes.SHA256()), salt_length=32), hashes.SHA256())
                buttons["复制激活码"].invoke()
                assert root.clipboard_get() == code
                fill(1, "bad")
                assert not output.get("1.0", "end-1c")
                assert "disabled" in buttons["复制激活码"].state()
                buttons["生成激活码"].invoke()
                error.assert_called_once()
                assert not output.get("1.0", "end-1c")
        print("Administrator GUI: paste machine, sign, copy code, invalidate stale output and reject malformed identity PASS")
    finally:
        root.destroy()


if __name__ == "__main__":
    with mock.patch.object(tk.Tk, "mainloop", check_gui):
        a.gui()
