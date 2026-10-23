#!/bin/bash

# ===============================================
# Omega Tech Black-Ops // Email Helper Functions
# Provides SMTP/system mail fallbacks with themed telemetry
# ===============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/theme_omega_black_ops.sh" ]; then
    # shellcheck disable=SC1091
    source "$SCRIPT_DIR/theme_omega_black_ops.sh"
fi

if ! declare -f omega_status >/dev/null 2>&1; then
    omega_status() { echo "$*"; }
fi

if ! declare -f omega_divider >/dev/null 2>&1; then
    omega_divider() { echo "----------------------------------------"; }
fi

if ! declare -f omega_prompt_text >/dev/null 2>&1; then
    omega_prompt_text() { printf "%s" "$1"; }
fi

# Send email using best available method
send_email_safe() {
    local to_email="$1"
    local subject="$2"
    local body="$3"
    local html_body="${4:-}"
    local attachment="${5:-}"

    omega_status info "[COMMS] Initializing transmission to ${to_email}"

    if command -v python3 &> /dev/null && [ -f "$SCRIPT_DIR/send_email.py" ]; then
        if [ -n "${SMTP_USERNAME:-}" ] && [ -n "${SMTP_PASSWORD:-}" ]; then
            omega_status info "[COMMS] Routing via Python SMTP tunnel"
            if [ -n "$html_body" ]; then
                if python3 "$SCRIPT_DIR/send_email.py" "$to_email" "$subject" "$body" --html "$html_body" ${attachment:+"--attachment" "$attachment"} --username "$SMTP_USERNAME" --password "$SMTP_PASSWORD" 2>&1; then
                    omega_status success "[COMMS] Signal delivered via Omega SMTP"
                    return 0
                fi
            else
                if python3 "$SCRIPT_DIR/send_email.py" "$to_email" "$subject" "$body" ${attachment:+"--attachment" "$attachment"} --username "$SMTP_USERNAME" --password "$SMTP_PASSWORD" 2>&1; then
                    omega_status success "[COMMS] Signal delivered via Omega SMTP"
                    return 0
                fi
            fi
            omega_status warn "[COMMS] Python SMTP path failed — attempting fallbacks"
        else
            omega_status warn "[COMMS] SMTP credentials missing — fallback required"
        fi
    fi

    if command -v mail &> /dev/null; then
        omega_status warn "[COMMS] Fallback to system mail agent"
        if [ -n "$attachment" ] && [ -f "$attachment" ]; then
            if echo "$body" | mail -s "$subject" -a "$attachment" "$to_email" 2>/dev/null; then
                omega_status success "[COMMS] System mail dispatched (attachment included)"
                return 0
            fi
        else
            if echo "$body" | mail -s "$subject" "$to_email" 2>/dev/null; then
                omega_status success "[COMMS] System mail dispatched"
                return 0
            fi
        fi
    fi

    if command -v sendmail &> /dev/null; then
        omega_status warn "[COMMS] Fallback to raw sendmail pipeline"
        if {
            echo "To: $to_email"
            echo "Subject: $subject"
            [ -n "$html_body" ] && echo "Content-Type: text/html; charset=UTF-8" || echo "Content-Type: text/plain; charset=UTF-8"
            echo ""
            [ -n "$html_body" ] && echo "$html_body" || echo "$body"
        } | sendmail "$to_email" 2>/dev/null; then
            omega_status success "[COMMS] sendmail pipeline dispatched"
            return 0
        fi
    fi

    omega_status error "[COMMS] Transmission failed — all channels offline"
    return 1
}

# Check email configuration
check_email_config() {
    omega_status info "[DIAGNOSTIC] Omega Tech Email Uplink"
    omega_divider

    if command -v python3 &> /dev/null && [ -f "$SCRIPT_DIR/send_email.py" ]; then
        omega_status success "Python SMTP dispatcher: ready"

        if [ -n "${SMTP_USERNAME:-}" ] && [ -n "${SMTP_PASSWORD:-}" ]; then
            omega_status success "SMTP credentials loaded for ${SMTP_USERNAME}"
            return 0
        else
            omega_status warn "Credentials missing — export SMTP_USERNAME / SMTP_PASSWORD"
            echo ""
            echo "To provision Omega SMTP uplink:"
            echo "  1. Generate an app-specific password (e.g., Gmail)."
            echo "  2. export SMTP_USERNAME='your-email@example.com'"
            echo "  3. export SMTP_PASSWORD='your-app-password'"
            return 1
        fi
    else
        omega_status warn "Python SMTP dispatcher unavailable"
    fi

    if command -v mail &> /dev/null; then
        omega_status warn "System mail detected (macOS delivery may vary)"
    fi

    omega_status error "No reliable email transport configured"
    return 1
}
