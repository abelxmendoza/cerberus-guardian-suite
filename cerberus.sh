#!/usr/bin/env bash
# ==============================================================================
# CERBERUS — The Guardian Security Suite (CerberusGuardian-SecuritySuite)
# Unified Cross-Platform CLI Entrypoint, Schema Distributor & Suite Verifier
# ==============================================================================
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
PINK='\033[1;35m'
RED='\033[0;31m'
NC='\033[0m'

banner() {
    echo -e "${PURPLE}======================================================================${NC}"
    echo -e "  ${CYAN}CERBERUS${NC} — The Guardian Security Suite (${PINK}CerberusGuardian-SecuritySuite${NC})"
    echo -e "  Three Platforms. One Guardian. (Windows · Linux · macOS)"
    echo -e "${PURPLE}======================================================================${NC}"
}

detect_os() {
    case "$(uname -s)" in
        Darwin*) echo "macos" ;;
        Linux*)  echo "linux" ;;
        MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
        *)       echo "unknown" ;;
    esac
}

sync_schemas() {
    python3 - "$ROOT_DIR" <<'PY'
import pathlib, shutil, sys

root = pathlib.Path(sys.argv[1])
shared = root / "shared"
for g in ["WindowsGuardianWatchdog", "LinuxGuardianWatchdog", "MacGuardianWatchdog"]:
    g_shared = root / g / "shared"
    if g_shared.exists():
        shutil.rmtree(g_shared)
    shutil.copytree(shared, g_shared)
    print(f"  [\033[0;32mDISTRIBUTED\033[0m] shared/ -> {g}/shared/")
PY
}

verify_suite() {
    banner
    echo "Verifying unified CerberusGuardian-SecuritySuite structure..."
    local errors=0

    # 1. Verify all 3 Guardians and key modules
    for path in \
        "WindowsGuardianWatchdog/WindowsGuardianWatchdog.csproj" \
        "WindowsGuardianWatchdog/Core/SecurityMonitor.cs" \
        "WindowsGuardianWatchdog/Core/FileIntegrityMonitor.cs" \
        "WindowsGuardianWatchdog/Core/Sensors/ChangeWatch.cs" \
        "WindowsGuardianWatchdog/Core/Quarantine/QuarantineVault.cs" \
        "WindowsGuardianWatchdog/Core/Network/ExposureInventory.cs" \
        "WindowsGuardianWatchdog/Core/SelfCheck/AppSelfCheck.cs" \
        "LinuxGuardianWatchdog/LinuxGuardianSuite/linux_guardian.sh" \
        "LinuxGuardianWatchdog/LinuxGuardianSuite/sensors.py" \
        "LinuxGuardianWatchdog/LinuxGuardianSuite/quarantine.py" \
        "LinuxGuardianWatchdog/LinuxGuardianSuite/exposure_inventory.py" \
        "LinuxGuardianWatchdog/LinuxGuardianSuite/self_check.py" \
        "LinuxGuardianWatchdog/LinuxGuardianSuiteUI/run_ui.sh" \
        "MacGuardianWatchdog/install.sh" \
        "MacGuardianWatchdog/MacGuardianSuite/mac_guardian.sh" \
        "MacGuardianWatchdog/MacGuardianSuite/mac_watchdog.sh" \
        "MacGuardianWatchdog/MacGuardianSuite/quarantine_manager.sh" \
        "MacGuardianWatchdog/MacGuardianSuite/self_check.sh" \
        "shared/pipeline/normalize_and_report.py"; do
        if [[ -f "$ROOT_DIR/$path" ]]; then
            echo -e "  [${GREEN}OK${NC}] $path"
        else
            echo -e "  [${RED}MISSING${NC}] $path"
            errors=$((errors + 1))
        fi
    done

    # 2. Verify unified governance docs across root + all 3 Guardians
    for doc in LICENSE SECURITY.md PRIVACY.md README.md; do
        for prefix in "" "WindowsGuardianWatchdog/" "LinuxGuardianWatchdog/" "MacGuardianWatchdog/"; do
            if [[ -f "$ROOT_DIR/${prefix}${doc}" ]]; then
                echo -e "  [${GREEN}OK${NC}] ${prefix}${doc}"
            else
                echo -e "  [${RED}MISSING${NC}] ${prefix}${doc}"
                errors=$((errors + 1))
            fi
        done
    done

    # 3. Verify canonical root shared/ schemas are synced across all 3 Guardians + run syntax & pipeline checks
    python3 - "$ROOT_DIR" <<'PY'
import json, pathlib, py_compile, subprocess, sys, xml.etree.ElementTree as ET

root = pathlib.Path(sys.argv[1])
schemas = [
    "shared/schemas/event_spec_v1.json",
    "shared/schemas/report_schema.json",
    "shared/schemas/config_schema.json",
    "shared/ml/feature_vector.schema.json",
    "shared/design/omega_design_system.json",
    "shared/compliance/gdpr.json",
    "shared/compliance/hipaa.json",
    "shared/compliance/pci_dss.json",
]

for rel in schemas:
    base_file = root / rel
    data = json.loads(base_file.read_text())
    for g in ["WindowsGuardianWatchdog", "LinuxGuardianWatchdog", "MacGuardianWatchdog"]:
        g_file = root / g / rel
        if not g_file.exists() or json.loads(g_file.read_text()) != data:
            print(f"  [MISMATCH] {g}/{rel} (run ./cerberus.sh --sync-schemas)")
            sys.exit(1)
    print(f"  [\033[0;32mSYNCED\033[0m] {rel} (canonical root -> all 3 Guardians)")

# Validate WindowsGuardianWatchdog.csproj XML structure
ET.parse(root / "WindowsGuardianWatchdog/WindowsGuardianWatchdog.csproj")
print("  [\033[0;32mOK\033[0m] WindowsGuardianWatchdog.csproj XML syntax verified")

# Validate Python & Bash syntax across MacGuardianWatchdog, LinuxGuardianWatchdog, and shared/pipeline
for g in ["shared/pipeline", "MacGuardianWatchdog/MacGuardianSuite", "LinuxGuardianWatchdog/LinuxGuardianSuite", "LinuxGuardianWatchdog/LinuxGuardianSuiteUI"]:
    for py in (root / g).rglob("*.py"):
        py_compile.compile(str(py), doraise=True)
    print(f"  [\033[0;32mOK\033[0m] Python syntax verified: {g}")

for g in ["MacGuardianWatchdog", "LinuxGuardianWatchdog"]:
    for sh in (root / g).rglob("*.sh"):
        first_line = sh.read_text(errors="ignore").splitlines()[0] if sh.stat().st_size > 0 else ""
        if "env bats" in first_line:
            continue
        subprocess.run(["bash", "-n", str(sh)], check=True)
    print(f"  [\033[0;32mOK\033[0m] Bash syntax verified: {g}")

# Verify end-to-end Detect -> Normalize -> Report pipeline
out = subprocess.check_output([sys.executable, str(root / "shared/pipeline/normalize_and_report.py"), "--demo"], text=True)
report = json.loads(out)
assert report["securityScore"] == 82 and len(report["events"]) == 3
print("  [\033[0;32mOK\033[0m] End-to-end Detect -> Normalize -> Report pipeline verified (score: 82/100)")
PY

    if [[ "$errors" -eq 0 ]]; then
        echo -e "\n${GREEN}All 3 Guardians, governance files, shared schemas, and telemetry pipeline are verified.${NC}"
    else
        echo -e "\n${RED}Verification failed with $errors missing file(s).${NC}"
        exit 1
    fi
}

show_status() {
    banner
    echo "Detected Host OS: $(detect_os)"
    echo ""
    echo "1. WindowsGuardianWatchdog : $ROOT_DIR/WindowsGuardianWatchdog (WinUI 3 / .NET 8)"
    echo "2. LinuxGuardianWatchdog   : $ROOT_DIR/LinuxGuardianWatchdog (GTK4 / Python / Bash)"
    echo "3. MacGuardianWatchdog     : $ROOT_DIR/MacGuardianWatchdog (SwiftUI / Bash / Python)"
    echo "4. CERBERUS Web Portal     : $ROOT_DIR/src (React / TypeScript / Vite)"
    echo "5. Canonical Shared Layer  : $ROOT_DIR/shared (Schemas, Design, Pipeline)"
}

case "${1:---status}" in
    --verify)
        verify_suite
        ;;
    --sync-schemas)
        banner
        sync_schemas
        ;;
    --report)
        python3 "$ROOT_DIR/shared/pipeline/normalize_and_report.py" --demo
        ;;
    --status)
        show_status
        ;;
    --web)
        cd "$ROOT_DIR"
        npm run dev
        ;;
    --launch)
        os="$(detect_os)"
        if [[ "$os" == "macos" ]]; then
            exec "$ROOT_DIR/MacGuardianWatchdog/mac_suite.sh"
        elif [[ "$os" == "linux" ]]; then
            exec "$ROOT_DIR/LinuxGuardianWatchdog/LinuxGuardianSuiteUI/run_ui.sh"
        else
            echo "On Windows, build and run WindowsGuardianWatchdog with: dotnet run --project WindowsGuardianWatchdog"
        fi
        ;;
    *)
        echo "Usage: ./cerberus.sh [--status | --verify | --sync-schemas | --report | --launch | --web]"
        exit 1
        ;;
esac
