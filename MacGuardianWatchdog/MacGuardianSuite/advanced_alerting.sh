#!/bin/bash

# ===============================
# Advanced Alerting Rules
# Customizable alert rules and escalation
# ===============================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"
source "$SCRIPT_DIR/config.sh"

# Load SMTP credentials from ~/.zshrc if not already set
if [ -z "${SMTP_USERNAME:-}" ] || [ -z "${SMTP_PASSWORD:-}" ]; then
    if [ -f ~/.zshrc ]; then
        eval $(grep "^export SMTP_USERNAME=" ~/.zshrc 2>/dev/null || true)
        eval $(grep "^export SMTP_PASSWORD=" ~/.zshrc 2>/dev/null || true)
    fi
fi

# Alert configuration
ALERT_RULES_FILE="${ALERT_RULES_FILE:-$HOME/.macguardian/alerts/rules.conf}"
ALERT_HISTORY="${ALERT_HISTORY:-$HOME/.macguardian/alerts/history.log}"
ALERT_ESCALATION="${ALERT_ESCALATION:-$HOME/.macguardian/alerts/escalation.log}"

mkdir -p "$(dirname "$ALERT_RULES_FILE")"

# Default alert rules
init_default_rules() {
    if [ ! -f "$ALERT_RULES_FILE" ]; then
        cat > "$ALERT_RULES_FILE" <<'EOFRULES'
# MacGuardian Alert Rules Configuration
# Format: rule_name|condition|severity|action|cooldown_seconds
# Note: Conditions with pipes should use \| or be in a function

# Critical Security Alerts
critical_threat|grep -qE "CRITICAL|THREAT"|critical|notify+log+email|0
filevault_disabled|! fdesetup status 2>/dev/null \| grep -q "On"|high|notify+log|300
sip_disabled|! csrutil status 2>/dev/null \| grep -q "enabled"|critical|notify+log+email|0
firewall_disabled|! /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null \| grep -q "enabled"|high|notify+log|300

# Process Alerts (simplified for now)
high_cpu_process|ps aux \| awk '{if(\$3>80) print}' \| wc -l \| grep -q "[1-9]"|medium|notify+log|600
suspicious_process|ps aux \| grep -qiE "miner|crypto|backdoor"|high|notify+log+email|300

# Network Alerts
suspicious_connection|netstat -an \| grep -qE ":4444|:5555|:6666|:7777"|high|notify+log|300

# File System Alerts
world_writable_files|find "$HOME" -type f -perm -002 2>/dev/null \| wc -l \| awk '{if(\$1>10) exit 0; exit 1}'|medium|notify+log|1800
suspicious_file_extension|find "$HOME" -maxdepth 4 -name "*.exe" -o -name "*.bat" 2>/dev/null \| wc -l \| awk '{if(\$1>0) exit 0; exit 1}'|medium|notify+log|600

# Backup Alerts
backup_stale|test $(($(date +%s) - $(stat -f %m "$(tmutil latestbackup 2>/dev/null)" 2>/dev/null || echo 0))) -gt 604800|high|notify+log|86400
backup_failed|! tmutil status 2>/dev/null \| grep -q "Running = 1"|high|notify+log|3600

# Error Alerts
critical_error|grep -qE "CRITICAL|FATAL" "$HOME/.macguardian/logs/macguardian.log" 2>/dev/null|critical|notify+log+email|0
EOFRULES
        success "Default alert rules created: $ALERT_RULES_FILE"
    fi
}

# Evaluate alert rule
evaluate_rule() {
    local rule_name="$1"
    local condition="$2"
    local severity="$3"
    local actions="$4"
    local cooldown="${5:-300}"
    
    # Check cooldown
    local last_trigger=0
    if [ -f "$ALERT_HISTORY" ]; then
        last_trigger=$(grep "^$rule_name|" "$ALERT_HISTORY" 2>/dev/null | tail -1 | cut -d'|' -f2 || echo "0")
    fi
    local current_time=$(date +%s)
    local time_since=$((current_time - last_trigger))
    
    # Ensure cooldown is a number
    cooldown=${cooldown:-300}
    if ! [[ "$cooldown" =~ ^[0-9]+$ ]]; then
        cooldown=300
    fi
    
    if [ $time_since -lt $cooldown ] 2>/dev/null; then
        return 0  # Still in cooldown
    fi
    
    # Evaluate condition (safely)
    set +e
    # Replace common variables in condition
    condition=$(echo "$condition" | sed "s|\$HOME|$HOME|g")
    
    # Simple condition evaluation
    if echo "$condition" | grep -q "grep\|find\|test\|\["; then
        # It's a shell command/condition
        if eval "$condition" &> /dev/null; then
            set -e
            # Condition met - trigger alert
            trigger_alert "$rule_name" "$severity" "$actions"
            return 1
        fi
    else
        # Try as a simple test
        if [ "$condition" = "true" ] || [ -n "$condition" ]; then
            set -e
            trigger_alert "$rule_name" "$severity" "$actions"
            return 1
        fi
    fi
    set -e
    
    return 0
}

# Trigger alert
trigger_alert() {
    local rule_name="$1"
    local severity="$2"
    local actions="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local timestamp_epoch=$(date +%s)
    
    # Log to history
    echo "$rule_name|$timestamp_epoch|$severity|$actions" >> "$ALERT_HISTORY"
    
    # Execute actions
    if echo "$actions" | grep -q "notify"; then
        send_alert_notification "$rule_name" "$severity"
    fi
    
    if echo "$actions" | grep -q "log"; then
        log_message "ALERT" "Rule triggered: $rule_name (Severity: $severity)"
    fi
    
    if echo "$actions" | grep -q "email"; then
        send_alert_email "$rule_name" "$severity"
    fi
    
    if echo "$actions" | grep -q "escalate"; then
        escalate_alert "$rule_name" "$severity"
    fi
}

# Send alert notification
send_alert_notification() {
    local rule_name="$1"
    local severity="$2"
    
    local title="MacGuardian Alert: $rule_name"
    local message="Security alert triggered: $rule_name"
    local priority="normal"
    
    if [ "$severity" = "critical" ]; then
        priority="critical"
        message="🚨 CRITICAL: $message"
    elif [ "$severity" = "high" ]; then
        message="⚠️ HIGH: $message"
        priority="critical"
    fi
    
    send_notification "$title" "$message" "true" "$priority"
}

# Send alert email
send_alert_email() {
    local rule_name="$1"
    local severity="$2"
    local email="${ALERT_EMAIL:-$REPORT_EMAIL}"
    
    if [ -z "$email" ]; then
        return 1
    fi
    
    local subject="MacGuardian Alert: $rule_name [$severity]"
    local body="Security alert triggered:\n\nRule: $rule_name\nSeverity: $severity\nTime: $(date)\n\nSystem: $(hostname)\n"
    
    # Try Python SMTP first (most reliable)
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if command -v python3 &> /dev/null && [ -f "$script_dir/send_email.py" ]; then
        if [ -n "${SMTP_USERNAME:-}" ] && [ -n "${SMTP_PASSWORD:-}" ]; then
            python3 "$script_dir/send_email.py" "$email" "$subject" "$(echo -e "$body")" --username "$SMTP_USERNAME" --password "$SMTP_PASSWORD" 2>/dev/null && return 0
        fi
    fi
    
    # Fallback: system mail (may not work on macOS)
    if command -v mail &> /dev/null; then
        echo -e "$body" | mail -s "$subject" "$email" 2>/dev/null || true
    fi
}

# Escalate alert
escalate_alert() {
    local rule_name="$1"
    local severity="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] ESCALATED: $rule_name (Severity: $severity)" >> "$ALERT_ESCALATION"
    
    # Additional escalation actions can be added here
    # e.g., SMS, PagerDuty integration, etc.
}

# Process all alert rules
process_alert_rules() {
    if [ ! -f "$ALERT_RULES_FILE" ]; then
        init_default_rules
    fi
    
    local triggered=0
    
    # Read and process each rule (handle pipes in conditions carefully)
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^#.*$ ]] && continue
        [ -z "$line" ] && continue
        
        # Parse rule - handle escaped pipes in conditions
        # Replace \| with a temporary marker, split, then restore
        local temp_line=$(echo "$line" | sed 's/\\|/__PIPE__/g')
        local rule_name=$(echo "$temp_line" | cut -d'|' -f1)
        local condition=$(echo "$temp_line" | cut -d'|' -f2 | sed 's/__PIPE__/|/g')
        local severity=$(echo "$temp_line" | cut -d'|' -f3)
        local actions=$(echo "$temp_line" | cut -d'|' -f4)
        local cooldown=$(echo "$temp_line" | cut -d'|' -f5)
        
        # Skip if rule_name is empty or looks like a comment
        [ -z "$rule_name" ] && continue
        
        # Expand variables in condition (safely)
        condition=$(eval "echo \"$condition\"" 2>/dev/null || echo "$condition")
        
        if evaluate_rule "$rule_name" "$condition" "$severity" "$actions" "${cooldown:-300}"; then
            triggered=$((triggered + 1))
        fi
    done < "$ALERT_RULES_FILE"
    
    return $triggered
}

# Add custom alert rule
add_alert_rule() {
    local rule_name="$1"
    local condition="$2"
    local severity="${3:-medium}"
    local actions="${4:-notify+log}"
    local cooldown="${5:-300}"
    
    echo "$rule_name|$condition|$severity|$actions|$cooldown" >> "$ALERT_RULES_FILE"
    success "Alert rule added: $rule_name"
}

# List alert rules
list_alert_rules() {
    echo "${bold}📋 Alert Rules${normal}"
    echo "----------------------------------------"
    
    if [ ! -f "$ALERT_RULES_FILE" ]; then
        warning "No alert rules configured"
        return 1
    fi
    
    while IFS= read -r line; do
        [[ "$line" =~ ^#.*$ ]] && continue
        [ -z "$line" ] && continue
        
        # Parse rule fields - handle escaped pipes
        local temp_line=$(echo "$line" | sed 's/\\|/__PIPE__/g')
        local rule_name=$(echo "$temp_line" | cut -d'|' -f1)
        local condition=$(echo "$temp_line" | cut -d'|' -f2 | sed 's/__PIPE__/|/g')
        local severity=$(echo "$temp_line" | cut -d'|' -f3)
        local actions=$(echo "$temp_line" | cut -d'|' -f4)
        local cooldown=$(echo "$temp_line" | cut -d'|' -f5)
        
        [ -z "$rule_name" ] && continue
        
        echo "  Rule: $rule_name"
        echo "    Condition: $condition"
        echo "    Severity: $severity"
        echo "    Actions: $actions"
        echo "    Cooldown: ${cooldown:-300}s"
        echo ""
    done < "$ALERT_RULES_FILE"
}

# Show alert history
show_alert_history() {
    echo "${bold}📜 Alert History${normal}"
    echo "----------------------------------------"
    
    if [ ! -f "$ALERT_HISTORY" ]; then
        echo "No alerts triggered yet"
        return 0
    fi
    
    tail -20 "$ALERT_HISTORY" | while IFS='|' read -r rule_name timestamp severity actions; do
        local date_str=$(date -r "$timestamp" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "unknown")
        echo "  [$date_str] $rule_name ($severity)"
    done
}

# Main function
main() {
    local action="${1:-process}"
    
    case "$action" in
        process)
            echo "${bold}🔔 Processing Alert Rules...${normal}"
            echo "----------------------------------------"
            process_alert_rules
            local triggered=$?
            if [ $triggered -gt 0 ]; then
                warning "$triggered alert(s) triggered"
            else
                success "No alerts triggered"
            fi
            ;;
        list)
            list_alert_rules
            ;;
        history)
            show_alert_history
            ;;
        add)
            if [ $# -lt 3 ]; then
                echo "Usage: $0 add <rule_name> <condition> [severity] [actions] [cooldown]"
                echo "Example: $0 add 'high_memory' 'memory_usage > 90' 'high' 'notify+log' '600'"
                exit 1
            fi
            add_alert_rule "$2" "$3" "${4:-medium}" "${5:-notify+log}" "${6:-300}"
            ;;
        *)
            echo "Usage: $0 {process|list|history|add}"
            echo ""
            echo "Commands:"
            echo "  process  - Process all alert rules"
            echo "  list     - List configured rules"
            echo "  history  - Show alert history"
            echo "  add      - Add new alert rule"
            exit 1
            ;;
    esac
}

# If run directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi

