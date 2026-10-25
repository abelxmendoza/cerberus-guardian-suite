# Cerberus source audit & open-source reuse plan — 2026-10-25

Scope: targeted static source inspection of LinuxGuardian, MacGuardian, WindowsGuardian and Hivemind. No host execution, builds, full-code scan, or runtime verification. Statuses describe inspected paths, **not product-wide absence**.

## Verified code observations
| Project | File | Observation | Assessment |
|---|---|---|---|
| LinuxGuardian | `LinuxGuardianSuite/exposure_inventory.py` | Substantial listener classifier, including SSH, Docker API, Ollama, PostgreSQL, ROS 2/DDS, MAVLink, VPN ports. Explicitly discloses process ownership and firewall rule visibility limitations for unprivileged runs. | Implemented read-only exposure inventory; test accuracy and IPv6/privilege boundaries. |
| LinuxGuardian | `LinuxGuardianSuite/threat_intel.py` | FireHOL level 1 and Feodo feeds, HTTPS host allowlist, redirect refusal, size cap, IPv4 parsing, cached state. | Implemented opt-in IPv4 reputation checking, not firewall blocking; verify feed licenses and false positives. |
| LinuxGuardian | `LinuxGuardianSuite/sensors.py` | Network process/connection monitoring with baseline learning and cooldown; docstring explicitly states nothing is blocked. | Detection, not prevention. |
| LinuxGuardian | `LinuxGuardianSuite/ai_safety.py` | Command validator, explicit allowlist, subprocess `shell=False`, timeout. | Useful local safety primitive; not general Hivemind enforcement. |
| MacGuardian | `MacGuardianSuite/mac_blueteam.sh` | Uses `lsof -i -P -n` for established connections; optional `osqueryi` and `nmap` paths. | Network visibility exists; inspect parsing/privilege behavior and test on macOS. |
| WindowsGuardian | `Core/BlueTeamDetector.cs` | `DetectNetworkThreatsAsync` queries `Win32_NetworkConnection` but contains a placeholder comment and returns an empty list. | **P1 gap in this method**: not functional network threat detection. |
| WindowsGuardian | `Core/SecurityMonitor.cs` | `MonitorNetworkConnections` queries `Win32_NetworkConnection`, has placeholder comment and silently swallows exceptions. | **P1 gap in this method**: no evidence of generated network alerts; inspect other modules separately. |
| Hivemind | `hooks/pre_tool_guard.py` | String-matching for `supabase db reset` and `git add .env`; hook catches all exceptions and returns `allow`. | **P0 policy bypass risk** if relied on as security enforcement. Scope is narrow and fail-open. Do not advertise as security boundary. |

## Priority fixes
1. **P0:** Treat Hivemind hook as convenience guard only. For managed execution, use independently enforced policy/sandbox and fail closed when authorization unavailable. Add tests for bypass variants, missing fields and malformed payload.
2. **P1:** Replace Windows placeholder network detectors with real OS-backed enumeration (e.g. .NET `IPGlobalProperties.GetActiveTcpConnections()` for connection state; native IP Helper APIs where owning PID is required), and explicit `unsupported` or `error` states rather than silent success. Check existing Windows exposure modules before implementation to reuse.
3. **P1:** Create canonical Cerberus feature manifest, event JSON schema and conformance fixtures; adapt native platform code, don't copy macOS shell into Windows.
4. **P2:** Build a single feature-parity test that verifies exposure classifications and severity from synthetic fixtures on all three OS runners.
5. **P2:** Add per-agent network visibility and explicit enforcement coverage map; distinguish observed-only from blocked. Avoid claiming universal outbound filtering without OS-level controls.
6. **P3:** Consider optional browser/DNS security modules only after validating concrete unmet user needs.

## Open-source reuse shortlist (evaluate licenses and maintenance before integration)
- **osquery** (Apache-2.0): cross-platform process/socket/service inventory. MacGuardian already invokes `osqueryi`; consider adapter across platforms instead of new collectors. https://osquery.io/
- **Open Policy Agent** (Apache-2.0): policy-as-code engine for shared authorization decisions. Requires an actual execution gateway/sandbox to enforce decisions. https://www.openpolicyagent.org/
- **Sigma rules / pySigma**: portable detection rule *format*, converters; rules need compatible telemetry and individual license checks. https://sigmahq.io/
- **Wazuh** (GPL-2.0): reference architecture for endpoint agents and centralized monitoring; use integration/interop where feasible rather than copying large codebase. https://wazuh.com/
- **OpenSnitch** (GPL-3.0): Linux application outbound firewall reference; assess licensing, privilege model and deployment cost before choosing it. https://github.com/evilsocket/opensnitch
- **LuLu** (GPL-3.0): macOS outbound firewall reference; examine OS extension requirements and licensing. https://github.com/objective-see/LuLu
- **Suricata** (GPL-2.0): network IDS/IPS; optional advanced adapter, not default laptop dependency. https://suricata.io/
- **Zeek** (BSD): network telemetry analysis; optional, potentially heavyweight. https://zeek.org/
- **promptfoo** (MIT): adversarial testing of prompt injection and agent/tool boundaries. https://www.promptfoo.dev/
- **OWASP AI Agent and MCP Security guidance**: threat model, least-privilege identities, MCP pinning, independent approvals, audit. https://owasp.github.io/DevSecOpsGuideline/2-Process/2-2-Develop/2-2-5-AI-Agent-and-MCP-Security/

## Architecture decision
Cerberus repo is **shared standards + design tokens + feature manifests + test contracts + release coordination**. The three native Guardians are the actual apps, work independently, and optionally consume pinned Cerberus releases. Feature promotion is **bidirectional proposal**, but merge only after OS-native implementation and CI validation. Hivemind is a separate optional agent workload, not the parent of Cerberus.

## Minimum next sprint
- Add `features/network-exposure.yaml` with shared classification and event schema.
- Add fixture-based tests and per-platform adapter contract; run on actual Windows/macOS/Linux CI.
- Fix the two Windows placeholder paths by calling an already-existing validated Windows exposure collector where possible.
- Add automated PR suggestions for feature parity, not auto-merge.
- Report per-platform coverage as `verified / implemented-untested / partial / unsupported`, never as blanket 'protected'.

## Validation gates
No 'production ready' claim until test commands, OS/version, artifact hashes, successful and failing scenarios, and permissions coverage are recorded. Audit is source-limited and cannot establish absence of compromise or complete protection.
