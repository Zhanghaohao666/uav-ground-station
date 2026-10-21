"""Generate disposable signing keys for tests; never reference the owner key."""
import base64
import copy
import datetime as dt
import importlib.util
import json
from pathlib import Path
import sys

repo = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("authority", repo / "tools/licensing/license_authority.py")
authority = importlib.util.module_from_spec(spec)
spec.loader.exec_module(authority)
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding, rsa


def generate(output):
    key = rsa.generate_private_key(public_exponent=65537, key_size=3072)
    other_key = rsa.generate_private_key(public_exponent=65537, key_size=3072)
    machine = "NGL1" + "-A1B2C3D4" * 8
    now = dt.datetime.now(dt.timezone.utc).replace(microsecond=0)
    valid = authority.issue(key, machine, "测试用户 <script> & 张三", now + dt.timedelta(days=30), now=now)
    permanent = authority.issue(key, machine, "永久用户", now=now)
    foreign = authority.issue(other_key, machine, "另一签发者", now=now)
    public = key.public_key()
    numbers = public.public_numbers()
    result = {
        "machine": machine, "now": authority.stamp(now),
        "key": {"modulus": numbers.n.to_bytes(384, "big").hex(), "exponent": "010001",
                "pem": public.public_bytes(serialization.Encoding.PEM, serialization.PublicFormat.SubjectPublicKeyInfo).decode(),
                "id": authority.key_id(public)},
        "valid": valid, "permanent": permanent, "foreign": foreign,
    }
    def variant(name, change):
        envelope = copy.deepcopy(valid)
        payload = json.loads(base64.b64decode(envelope["payload"]))
        change(payload)
        message = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        envelope["payload"] = base64.b64encode(message).decode()
        envelope["signature"] = base64.b64encode(key.sign(message, padding.PSS(mgf=padding.MGF1(hashes.SHA256()), salt_length=32), hashes.SHA256())).decode()
        result[name] = envelope
    variant("wrong_product", lambda p: p.update(product="OtherProduct"))
    variant("wrong_machine", lambda p: p.update(machine="NGL1" + "-11111111" * 8))
    variant("no_feature", lambda p: p.update(features=[]))
    variant("wrong_schema", lambda p: p.update(schema=2))
    variant("bad_date", lambda p: p.update(expires_at="2026-02-30T00:00:00Z"))
    variant("no_expiry", lambda p: p.pop("expires_at"))
    variant("blank_customer", lambda p: p.update(customer="  "))
    variant("future", lambda p: p.update(not_before=authority.stamp(now + dt.timedelta(days=1))))
    variant("expired", lambda p: p.update(issued_at=authority.stamp(now - dt.timedelta(days=10)),
        not_before=authority.stamp(now - dt.timedelta(days=10)), expires_at=authority.stamp(now - dt.timedelta(days=1))))
    Path(output).write_text(json.dumps(result, ensure_ascii=False), encoding="utf-8")


if __name__ == "__main__":
    generate(sys.argv[1])
