#!/bin/bash

# Omega Tech Black-Ops // MacGuardian Watchdog Control Console
# Interactive menu to run Mac Guardian tools with the Omega theme styling

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Load theme if available
OMEGA_THEME_ACTIVE=0
if [ -f "$SCRIPT_DIR/theme_omega_black_ops.sh" ]; then
    # shellcheck disable=SC1091
    source "$SCRIPT_DIR/theme_omega_black_ops.sh"
    OMEGA_THEME_ACTIVE=1
else
    # Minimal fallback definitions to avoid script failure
    OMEGA_RESET="\033[0m"
    OMEGA_ACCENT_PURPLE="\033[35m"
    OMEGA_ACCENT_RED="\033[31m"
    OMEGA_ACCENT_YELLOW="\033[33m"
    OMEGA_FG_MAIN="\033[37m"
    OMEGA_FG_SUBTLE="\033[90m"
    OMEGA_BOLD="\033[1m"
    OMEGA_THEME_NAME="Omega Tech Black-Ops"
    OMEGA_PROMPT_GLIPH="Ω"
    omega_banner() {
        printf "${OMEGA_BOLD}${OMEGA_ACCENT_PURPLE}=== %s ===${OMEGA_RESET}\n" "$OMEGA_THEME_NAME"
    }
    omega_divider() {
        printf "${OMEGA_FG_SUBTLE}----------------------------------------------${OMEGA_RESET}\n"
    }
    omega_echo() {
        local color="$1"; shift
        printf "%b%s%b\n" "$color" "$*" "${OMEGA_RESET}"
    }
    omega_status() {
        local level="$1"; shift
        case "$level" in
            success) omega_echo "${OMEGA_ACCENT_PURPLE}${OMEGA_BOLD}" "$*" ;;
            info)    omega_echo "${OMEGA_FG_MAIN}" "$*" ;;
            warn)    omega_echo "${OMEGA_ACCENT_YELLOW}${OMEGA_BOLD}" "$*" ;;
            critical|error) omega_echo "${OMEGA_ACCENT_RED}${OMEGA_BOLD}" "$*" ;;
            *) omega_echo "${OMEGA_FG_MAIN}" "$*" ;;
        esac
    }
    omega_prompt_text() { printf "%b%s%b" "${OMEGA_ACCENT_PURPLE}${OMEGA_BOLD}" "$1" "${OMEGA_RESET}"; }
    omega_menu_option() { printf "${OMEGA_ACCENT_PURPLE}${OMEGA_BOLD}%2s${OMEGA_RESET} ${OMEGA_FG_MAIN}%s${OMEGA_RESET}\n" "$1" "$2"; }
    omega_menu_section() { omega_status info "$1"; omega_divider; }
    omega_label_value() { printf "${OMEGA_FG_SUBTLE}${OMEGA_BOLD}%s${OMEGA_RESET} ${OMEGA_FG_MAIN}%s${OMEGA_RESET}\n" "$1" "$2"; }
fi

press_enter() {
    read -r -p "$(omega_prompt_text "Press ENTER to redeploy...")" _
}

# Validate script presence and permissions
check_script() {
    local script="$1"
    if [ ! -f "$script" ]; then
        omega_status critical "${script} missing from ops bay"
        return 1
    fi
    chmod +x "$script"
    return 0
}

run_script() {
    local script="$1"
    local codename="$2"

    if ! check_script "$script"; then
        return 1
    fi

    echo ""
    omega_status info "Deploying ${codename}..."
    omega_divider
    if "./$(basename "$script")"; then
        echo ""
        omega_status success "${codename} reported mission success"
        return 0
    else
        echo ""
        omega_status error "${codename} encountered resistance"
        return 1
    fi
}

run_all_core_ops() {
    omega_status info "Executing Black-Ops full chain"
    omega_divider
    if run_script "mac_guardian.sh" "Mac Guardian" && \
       run_script "mac_watchdog.sh" "Mac Watchdog" && \
       run_script "mac_blueteam.sh" "Mac Blue Team" && \
       run_script "mac_ai.sh" "Mac AI" && \
       run_script "mac_security_audit.sh" "Mac Security Audit"; then
        echo ""
        omega_status info "Intel: Trigger remediation to auto-patch exposed surfaces"
        read -r -p "$(omega_prompt_text "Deploy Mac Remediation now? (y/n): ")" run_remediation
        if [[ "${run_remediation}" =~ ^[Yy]$ ]]; then
            echo ""
            run_script "mac_remediation.sh" "Mac Remediation"
        fi
    fi
}

draw_menu() {
    clear
    omega_banner
    omega_label_value "THEME:" "${OMEGA_THEME_NAME:-Omega Tech Black-Ops}"
    omega_label_value "OPS HUB:" "MacGuardian Watchdog Suite"
    omega_label_value "PROFILE:" "${OMEGA_PROMPT_GLIPH:-Ω} // ${USER:-agent}"
    echo ""
    omega_divider
    omega_status info "Select your next operation"

    echo ""
    omega_menu_option "01" "Mac Guardian — Cleanup & Adaptive Security"
    omega_menu_option "02" "Mac Watchdog — File Integrity Sentinel"
    omega_menu_option "03" "Mac Blue Team — Adversary Hunting"
    omega_menu_option "04" "Mac AI — Intelligence Synthesis"
    omega_menu_option "05" "Mac Security Audit — Deep System Recon"
    omega_menu_option "06" "Mac Remediation — Auto-Fix Strike"
    omega_menu_option "07" "Run Core Ops Chain"
    omega_menu_option "08" "Verify Suite Integrity"
    omega_menu_option "09" "Error Vault — Review & Patch"
    omega_menu_option "10" "Hardening Assessment"
    omega_menu_option "11" "Generate Tactical Report"
    omega_menu_option "12" "Phase One Systems Setup"
    omega_menu_option "13" "Fire Test Transmission"
    omega_menu_option "14" "Performance Monitor — Bottlenecks"
    omega_menu_option "15" "Advanced Reporting Arsenal"
    omega_menu_option "16" "Hardening Auto-Fix"
    omega_menu_option "17" "Privacy Mode Console"
    omega_menu_option "18" "Zero Trust Recon"
    omega_menu_option "19" "Zero Trust Auto-Strike"
    omega_menu_option "20" "Threat Intelligence Feeds"
    omega_menu_option "21" "Diamond Model Correlation"
    omega_menu_option "22" "Exit Ops Center"
    echo ""
}

while true; do
    draw_menu
    read -r -p "$(omega_prompt_text "${OMEGA_PROMPT_GLIPH:-Ω} Select mission (01-22): ")" choice
    echo ""
    case "$choice" in
        1|01)
            run_script "mac_guardian.sh" "Mac Guardian"
            press_enter
            ;;
        2|02)
            run_script "mac_watchdog.sh" "Mac Watchdog"
            press_enter
            ;;
        3|03)
            run_script "mac_blueteam.sh" "Mac Blue Team"
            press_enter
            ;;
        4|04)
            run_script "mac_ai.sh" "Mac AI"
            press_enter
            ;;
        5|05)
            run_script "mac_security_audit.sh" "Mac Security Audit"
            press_enter
            ;;
        6|06)
            run_script "mac_remediation.sh" "Mac Remediation"
            press_enter
            ;;
        7|07)
            run_all_core_ops
            press_enter
            ;;
        8|08)
            run_script "verify_suite.sh" "Suite Verification"
            press_enter
            ;;
        9|09)
            run_script "view_errors.sh" "Error Vault"
            press_enter
            ;;
        10)
            run_script "hardening_assessment.sh" "Hardening Assessment"
            press_enter
            ;;
        11)
            run_script "scheduled_reports.sh" "Security Report Generator"
            press_enter
            ;;
        12)
            run_script "setup_phase1_features.sh" "Phase 1 Systems Setup"
            press_enter
            ;;
        13)
            run_script "test_email.sh" "Email Signal Test"
            press_enter
            ;;
        14)
            if [ -f "performance_monitor.sh" ]; then
                omega_status info "Performance Monitor"
                omega_divider
                ./performance_monitor.sh bottlenecks
                echo ""
                ./performance_monitor.sh suggestions
                echo ""
            else
                omega_status warn "Performance monitor module offline"
            fi
            press_enter
            ;;
        15)
            if [ -f "advanced_reporting.sh" ]; then
                omega_status info "Advanced Reporting Arsenal"
                omega_divider
                echo "1) Generate Comparison Report"
                echo "2) Export Report to PDF"
                echo "3) Generate Executive Summary"
                echo "4) Create Custom Template"
                read -r -p "$(omega_prompt_text "${OMEGA_PROMPT_GLIPH:-Ω} Select payload (1-4): ")" report_choice
                case "$report_choice" in
                    1)
                        latest_report=$(ls -t "$HOME/.macguardian/reports"/*.html 2>/dev/null | head -1)
                        if [ -n "$latest_report" ]; then
                            ./advanced_reporting.sh compare "$latest_report"
                        else
                            omega_status warn "No reports detected — generate one first"
                        fi
                        ;;
                    2)
                        latest_report=$(ls -t "$HOME/.macguardian/reports"/*.html 2>/dev/null | head -1)
                        if [ -n "$latest_report" ]; then
                            ./advanced_reporting.sh pdf "$latest_report"
                        else
                            omega_status warn "No reports detected — generate one first"
                        fi
                        ;;
                    3)
                        ./advanced_reporting.sh executive
                        ;;
                    4)
                        ./advanced_reporting.sh template
                        ;;
                esac
            else
                omega_status warn "Advanced reporting module offline"
            fi
            press_enter
            ;;
        16)
            if [ -f "hardening_auto_fix.sh" ]; then
                omega_status info "Hardening Auto-Fix"
                omega_divider
                echo "1) Dry-run (show planned fixes)"
                echo "2) Execute fixes (confirm each)"
                echo "3) Auto-fix all (no confirmation)"
                read -r -p "$(omega_prompt_text "${OMEGA_PROMPT_GLIPH:-Ω} Select tactic (1-3): ")" fix_choice
                case "$fix_choice" in
                    1) ./hardening_auto_fix.sh all ;;
                    2) ./hardening_auto_fix.sh all --execute ;;
                    3) ./hardening_auto_fix.sh all --execute --yes ;;
                esac
            else
                omega_status warn "Hardening auto-fix module offline"
            fi
            press_enter
            ;;
        17)
            if [ -f "privacy_mode.sh" ]; then
                omega_status info "Privacy Mode Console"
                omega_divider
                ./privacy_mode.sh status
                echo ""
                echo "1) Minimal (essential checks)"
                echo "2) Light (basic security)"
                echo "3) Standard (full suite)"
                echo "4) Full (maximum visibility)"
                read -r -p "$(omega_prompt_text "${OMEGA_PROMPT_GLIPH:-Ω} Select mode (1-4 or Enter to abort): ")" privacy_choice
                case "$privacy_choice" in
                    1) ./privacy_mode.sh minimal ;;
                    2) ./privacy_mode.sh light ;;
                    3) ./privacy_mode.sh standard ;;
                    4) ./privacy_mode.sh full ;;
                esac
            else
                omega_status warn "Privacy module offline"
            fi
            press_enter
            ;;
        18)
            if [ -f "zero_trust_assessment.sh" ]; then
                run_script "zero_trust_assessment.sh" "Zero Trust Assessment"
            else
                omega_status warn "Zero Trust assessment module offline"
            fi
            press_enter
            ;;
        19)
            if [ -f "zero_trust_auto_fix.sh" ]; then
                omega_status info "Zero Trust Auto-Strike"
                omega_divider
                echo "1) Dry-run (review plan)"
                echo "2) Execute fixes (confirm each)"
                echo "3) Auto-fix all (no confirmation)"
                read -r -p "$(omega_prompt_text "${OMEGA_PROMPT_GLIPH:-Ω} Select tactic (1-3): ")" fix_choice
                case "$fix_choice" in
                    1) ./zero_trust_auto_fix.sh all ;;
                    2) ./zero_trust_auto_fix.sh all --execute ;;
                    3) ./zero_trust_auto_fix.sh all --execute --yes ;;
                esac
            else
                omega_status warn "Zero Trust auto-fix module offline"
            fi
            press_enter
            ;;
        20)
            if [ -f "threat_intel_feeds.sh" ]; then
                omega_status info "Threat Intelligence Feeds"
                omega_divider
                echo "1) Update threat feeds"
                echo "2) Check IOC (ip/domain/hash/url)"
                echo "3) Export to STIX format"
                read -r -p "$(omega_prompt_text "${OMEGA_PROMPT_GLIPH:-Ω} Select directive (1-3): ")" feed_choice
                case "$feed_choice" in
                    1)
                        ./threat_intel_feeds.sh update
                        ;;
                    2)
                        read -r -p "$(omega_prompt_text "Enter IOC type: ")" ioc_type
                        read -r -p "$(omega_prompt_text "Enter IOC value: ")" ioc_value
                        ./threat_intel_feeds.sh check "$ioc_type" "$ioc_value"
                        ;;
                    3)
                        ./threat_intel_feeds.sh export
                        ;;
                esac
            else
                omega_status warn "Threat intel feeds module offline"
            fi
            press_enter
            ;;
        21)
            run_script "diamond_model_correlation.sh" "Diamond Model Correlation"
            press_enter
            ;;
        22)
            omega_status info "Exiting Omega Tech Ops Center"
            echo ""
            exit 0
            ;;
        *)
            omega_status warn "Invalid directive. Choose 01-22"
            sleep 1
            ;;
    esac

done
