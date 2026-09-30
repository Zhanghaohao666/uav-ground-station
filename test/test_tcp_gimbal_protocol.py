import struct
import unittest

from tcp_gimbal_mock_server import (
    CMD_DETECTION_CONTROL,
    CMD_TRACK_BOX,
    CMD_TRACK_XY,
    describe_command,
    make_frame,
)


class GimbalProtocolTest(unittest.TestCase):
    def test_track_xy_is_little_endian_int16(self):
        payload = struct.pack("<hh", 960, 540)
        self.assertEqual(
            make_frame(CMD_TRACK_XY, payload),
            bytes.fromhex("aa 01 04 00 c0 03 1c 02"),
        )
        self.assertEqual(describe_command(CMD_TRACK_XY, payload), "TRACK_XY x=960 y=540")

    def test_track_box_is_little_endian_int16_xywh(self):
        payload = struct.pack("<hhhh", 480, 270, 960, 540)
        self.assertEqual(
            make_frame(CMD_TRACK_BOX, payload),
            bytes.fromhex("aa 04 08 00 e0 01 0e 01 c0 03 1c 02"),
        )
        self.assertEqual(
            describe_command(CMD_TRACK_BOX, payload),
            "TRACK_BOX x=480 y=270 w=960 h=540",
        )

    def test_detection_control_uses_one_byte_boolean(self):
        enabled_payload = struct.pack("<B", 1)
        disabled_payload = struct.pack("<B", 0)
        self.assertEqual(
            make_frame(CMD_DETECTION_CONTROL, enabled_payload),
            bytes.fromhex("aa 05 01 00 01"),
        )
        self.assertEqual(
            make_frame(CMD_DETECTION_CONTROL, disabled_payload),
            bytes.fromhex("aa 05 01 00 00"),
        )
        self.assertEqual(
            describe_command(CMD_DETECTION_CONTROL, enabled_payload),
            "DETECTION_CONTROL enabled=1",
        )


if __name__ == "__main__":
    unittest.main()
