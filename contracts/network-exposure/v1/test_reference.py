"""Run: python -m unittest discover -s contracts/network-exposure/v1 -p 'test_*.py'"""
import json
import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).parent))
from reference import normalize

ROOT = pathlib.Path(__file__).parent

class NetworkExposureContractTests(unittest.TestCase):
    def test_fixtures(self):
        for case in json.loads((ROOT / "fixtures.json").read_text()):
            with self.subTest(case=case["id"]):
                result = normalize(case["input"])
                for key, expected in case["expected"].items():
                    self.assertEqual(result[key], expected)

    def test_rejects_bad_data(self):
        base = json.loads((ROOT / "fixtures.json").read_text())[0]["input"]
        for patch in ({"port": 0}, {"port": True}, {"protocol": "icmp"}, {"bind_address": "not-ip"}, {"firewall_verdict": "blocked"}, {"service_class": "everything"}):
            with self.subTest(patch=patch), self.assertRaises(ValueError):
                normalize({**base, **patch})

    def test_does_not_claim_internet_reachability(self):
        base = json.loads((ROOT / "fixtures.json").read_text())[1]["input"]
        result = normalize(base)
        self.assertNotIn("internet_reachable", result)
        self.assertEqual(result["firewall_verdict"], "unknown")

if __name__ == "__main__":
    unittest.main()
