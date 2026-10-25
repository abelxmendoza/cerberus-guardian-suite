import json
import pathlib
import sys
import unittest
sys.path.insert(0, str(pathlib.Path(__file__).parent))
from linux_adapter import convert, parse_jsonl

class AdapterTests(unittest.TestCase):
    def test_linuxguardian_jsonl(self):
        meta = {"type": "meta", "ss_ok": True}
        service = {"type": "service", "id": "tcp:5432:postgres", "proto": "tcp",
                   "port": 5432, "class": "database", "severity": "critical",
                   "owner_known": True, "binds": [{"host": "0.0.0.0", "iface": ""}]}
        rows = parse_jsonl([json.dumps(meta), json.dumps(service)])
        self.assertEqual(rows[0]["reachability"], "non_loopback")
        self.assertEqual(rows[0]["firewall_verdict"], "unknown")
        self.assertEqual(rows[0]["source_id"], service["id"])
    def test_dual_stack(self):
        service = {"type": "service", "proto": "tcp", "port": 22, "class": "remote_login",
                   "owner_known": False, "binds": [{"host": "127.0.0.1"}, {"host": "::"}]}
        rows = convert({"type": "meta", "ss_ok": True}, [service])
        self.assertEqual([r["reachability"] for r in rows], ["loopback", "non_loopback"])
    def test_no_silent_success(self):
        with self.assertRaises(ValueError):
            convert({"type": "meta", "ss_ok": False}, [])
        with self.assertRaises(ValueError):
            parse_jsonl([])
        with self.assertRaises(ValueError):
            convert({"type": "meta", "ss_ok": True},
                    [{"type": "service", "proto": "tcp", "port": 80,
                      "class": "web", "binds": [{"host": "*"}]}])
if __name__ == "__main__":
    unittest.main()
