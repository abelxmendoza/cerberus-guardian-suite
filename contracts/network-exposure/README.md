# Network Exposure v1 — shared Guardian contract

**First working Cerberus synchronization primitive.** This is a common feature definition, fixture corpus, and standard-library Python reference validator. It is **not** a native adapter or network protection feature yet.

Run from the repository root:

```bash
python -m unittest discover -s contracts/network-exposure/v1 -p 'test_*.py' -v
```

Next: create adapter outputs for MacGuardian (lsof/osquery), LinuxGuardian (exposure_inventory.py), and WindowsGuardian (existing exposure collector / IP Helper APIs), then validate each against this contract on the relevant OS CI runner. Do not copy platform-specific implementations or auto-merge generated code. An individual Guardian must still work when Cerberus is absent.

Important: `non_loopback` means the service binds to a non-loopback address; it **does not** mean the service is reachable from the public internet. Firewall verdict must remain `unknown` without a verified evaluator. No code in this contract blocks traffic.

Future sync flow: Guardian change -> proposed Cerberus contract/fixture update -> human review -> platform-specific PRs -> OS-native CI -> parity report.
