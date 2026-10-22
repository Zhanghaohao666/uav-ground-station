import datetime as dt
import base64
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import padding

spec = importlib.util.spec_from_file_location("authority", Path(__file__).resolve().parents[2] / "tools/licensing/license_authority.py")
a = importlib.util.module_from_spec(spec)
spec.loader.exec_module(a)


class AuthorityTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.key = rsa.generate_private_key(public_exponent=65537, key_size=3072)
        cls.machine = "NGL1" + "-A1B2C3D4" * 8

    def test_key_creation_is_exclusive_and_private(self):
        with tempfile.TemporaryDirectory() as directory:
            private = Path(directory) / "owner.private.pem"
            header = Path(directory) / "public.h"
            identifier = a.initialize(private, header)
            self.assertEqual(identifier, a.key_id(a.load_key(private).public_key()))
            self.assertNotIn("PRIVATE KEY", header.read_text())
            if __import__("os").name != "nt":
                self.assertEqual(private.stat().st_mode & 0o777, 0o600)
            with self.assertRaises(ValueError):
                a.initialize(private, header)

    def test_encrypted_key_roundtrip(self):
        with tempfile.TemporaryDirectory() as directory:
            private = Path(directory) / "owner.private.pem"
            a.initialize(private, Path(directory) / "public.h", b"test-password")
            with self.assertRaises(TypeError):
                a.load_key(private)
            a.load_key(private, b"test-password")

    def test_invalid_machine_customer_and_expiration(self):
        for machine, customer, expiry in [("bad", "customer", None), (self.machine, "", None),
            (self.machine, "customer", dt.datetime.now(a.UTC) - dt.timedelta(days=1))]:
            with self.assertRaises(ValueError):
                a.issue(self.key, machine, customer, expiry)

    def test_request_key_must_match(self):
        with self.assertRaises(ValueError):
            a.issue(self.key, self.machine, "customer", request_key_id="0" * 24)

    def test_date_is_inclusive_china_time(self):
        self.assertEqual(a.expiration_date("2030-01-01"), dt.datetime(2030, 1, 1, 16, tzinfo=a.UTC))
        self.assertIsNone(a.expiration_date(""))
        with self.assertRaises(ValueError):
            a.expiration_date("2030-02-30")

    def test_no_overwrite_and_request_rejects_bad_data(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "license.nglic"
            value = a.issue(self.key, self.machine, "customer")
            a.write_license(path, value)
            with self.assertRaises(FileExistsError):
                a.write_license(path, value)
            request = Path(directory) / "request.ngreq"
            request.write_text(json.dumps({"schema": 1, "product": a.PRODUCT, "machine": self.machine,
                                           "key_id": a.key_id(self.key.public_key())}))
            self.assertEqual(a.read_request(request)["machine"], self.machine)
            request.write_text("x" * 65537)
            with self.assertRaises(ValueError):
                a.read_request(request)

    def test_copyable_code_preserves_original_signature(self):
        envelope = a.issue(self.key, self.machine, "测试用户")
        code = a.activation_code(envelope)
        prefix, identifier, message, signature = code.split(".")
        self.assertEqual(prefix, "NGAC1")
        self.assertEqual(identifier, a.key_id(self.key.public_key()))
        self.assertTrue(code.isascii())
        self.assertNotIn("=", code)
        decode = lambda text: base64.urlsafe_b64decode(text + "=" * (-len(text) % 4))
        self.assertEqual(decode(message), base64.b64decode(envelope["payload"]))
        self.assertEqual(decode(signature), base64.b64decode(envelope["signature"]))
        self.key.public_key().verify(decode(signature), decode(message),
            padding.PSS(mgf=padding.MGF1(hashes.SHA256()), salt_length=32), hashes.SHA256())
        self.assertLess(len(code), 2000)

    def test_code_rejects_incompatible_envelope(self):
        envelope = a.issue(self.key, self.machine, "customer")
        for changed in [{"format": "wrong"}, {"algorithm": "none"}, {"key_id": "bad"},
                        {"signature": "AA=="}, {"payload": "!!!!"}]:
            with self.assertRaises(ValueError):
                a.activation_code(dict(envelope, **changed))


if __name__ == "__main__":
    unittest.main()
