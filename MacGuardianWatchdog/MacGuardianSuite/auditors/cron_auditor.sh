#!/bin/bash

# ===============================
# Cron Job Auditor
# Monitors cron jobs for changes and suspicious patterns
# Event Spec v1.0.0 compliant
# ===============================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUITE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source core modules
source "$SUITE_DIR/core/validators.sh" 2>/dev/null || true
source "$SUITE_DIR/core/logging.sh" 2>/dev/null || true
source "$SUITE_DIR/core/system_state.sh" 2>/dev/null || true
source "$SUITE_DIR/core/privilege_check.sh" 2>/dev/null || true
source "$SUITE_DIR/daemons/event_writer.sh" 2>/dev/null || true

BASELINE_DIR="$HOME/.macguardian/baselines"
CRON_BASELINE="$BASELINE_DIR/cron_baseline.json"
AUDIT_OUTPUT="$HOME/.macguardian/audits/cron_audit_$(date +%Y%m%d_%H%M%S).json"

mkdir -p "$BASELINE_DIR" "$(dirname "$AUDIT_OUTPUT")"

# Initialize baseline
init_cron_baseline() {
    if [ ! -f "$CRON_BASELINE" ]; then
        log_auditor "cron_auditor" "INFO" "Creating cron job baseline..."
        
        local cron_jobs="[]"
        local cron_hash=""
        
        # Get user crontab
        if crontab -l 2>/dev/null | grep -v "^#" | grep -v "^$" > /dev/null; then
            cron_hash=$(crontab -l 2>/dev/null | shasum -a 256 | cut -d' ' -f1 || echo "")
            
            # Parse cron jobs (simplified)
            local jobs_array="["
            local first=true
            crontab -l 2>/dev/null | grep -v "^#" | grep -v "^$" | while IFS= read -r line; do
                if [ -n "$line" ]; then
                    if [ "$first" = true ]; then
                        first=false
                    else
                        jobs_array="$jobs_array,"
                    fi
                    local escaped_line=$(echo "$line" | sed 's/"/\\"/g')
                    jobs_array="$jobs_array\"$escaped_line\""
                fi
            done
            jobs_array="$jobs_array]"
            cron_jobs="$jobs_array"
        fi
        
        # System crontabs
        local system_crontabs="[]"
        if [ -d "/etc/cron.d" ]; then
            local sys_first=true
            local sys_array="["
            for file in /etc/cron.d/*; do
                if [ -f "$file" ]; then
                    if [ "$sys_first" = true ]; then
                        sys_first=false
                    else
                        sys_array="$sys_array,"
                    fi
                    local file_hash=$(shasum -a 256 "$file" 2>/dev/null | cut -d' ' -f1 || echo "")
                    sys_array="$sys_array{\"file\":\"$file\",\"hash\":\"$file_hash\"}"
                fi
            done
            sys_array="$sys_array]"
            system_crontabs="$sys_array"
        fi
        
        cat > "$CRON_BASELINE" <<EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "user_crontab_hash": "$cron_hash",
  "user_cron_jobs": $cron_jobs,
  "system_crontabs": $system_crontabs
}
EOF
        
        log_auditor "cron_auditor" "INFO" "Cron baseline created"
    fi
}

# Audit cron jobs
audit_cron_jobs() {
    local issues=0
    local findings="[]"
    
    # Load baseline
    if [ ! -f "$CRON_BASELINE" ]; then
        init_cron_baseline
        return 0
    fi
    
    # Get current crontab hash
    local current_hash=""
    if crontab -l 2>/dev/null | grep -v "^#" | grep -v "^$" > /dev/null; then
        current_hash=$(crontab -l 2>/dev/null | shasum -a 256 | cut -d' ' -f1 || echo "")
    fi
    
    local baseline_hash=$(grep -o '"user_crontab_hash":"[^"]*"' "$CRON_BASELINE" 2>/dev/null | cut -d'"' -f4 || echo "")
    
    # Check for changes
    if [ -n "$baseline_hash" ] && [ -n "$current_hash" ] && [ "$current_hash" != "$baseline_hash" ]; then
        issues=$((issues + 1))
        
        # Emit Event Spec v1.0.0 event
        local context_json="{\"change_type\": \"modified\", \"file\": \"crontab\", \"old_hash\": \"$baseline_hash\", \"new_hash\": \"$current_hash\"}"
        write_event "cron_modification" "high" "cron_auditor" "$context_json"
        log_auditor "cron_auditor" "WARNING" "Crontab has been modified"
    fi
    
    # Check for suspicious patterns
    local suspicious_jobs=""
    if crontab -l 2>/dev/null | grep -qiE "(curl|wget|bash|sh|python|perl).*http"; then
        issues=$((issues + 1))
        local job_line=$(crontab -l 2>/dev/null | grep -iE "(curl|wget|bash|sh|python|perl).*http" | head -1)
        local escaped_job=$(echo "$job_line" | sed 's/"/\\"/g')
        local context_json="{\"change_type\": \"suspicious_pattern\", \"pattern\": \"downloads_from_internet\", \"job\": \"$escaped_job\"}"
        write_event "cron_modification" "high" "cron_auditor" "$context_json"
        log_auditor "cron_auditor" "WARNING" "Suspicious cron job detected: downloads from internet"
    fi
    
    if crontab -l 2>/dev/null | grep -qiE "(base64|eval|exec|decode)"; then
        issues=$((issues + 1))
        local job_line=$(crontab -l 2>/dev/null | grep -iE "(base64|eval|exec|decode)" | head -1)
        local escaped_job=$(echo "$job_line" | sed 's/"/\\"/g')
        local context_json="{\"change_type\": \"suspicious_pattern\", \"pattern\": \"obfuscated_commands\", \"job\": \"$escaped_job\"}"
        write_event "cron_modification" "high" "cron_auditor" "$context_json"
        log_auditor "cron_auditor" "WARNING" "Suspicious cron job detected: obfuscated commands"
    fi
    
    # Check system crontabs
    if [ -d "/etc/cron.d" ]; then
        for file in /etc/cron.d/*; do
            if [ -f "$file" ]; then
                local current_file_hash=$(shasum -a 256 "$file" 2>/dev/null | cut -d' ' -f1 || echo "")
                local baseline_file_hash=$(grep -o "\"file\":\"$file\".*\"hash\":\"[^\"]*\"" "$CRON_BASELINE" 2>/dev/null | grep -o '"hash":"[^"]*"' | cut -d'"' -f4 || echo "")
                
                if [ -n "$baseline_file_hash" ] && [ "$current_file_hash" != "$baseline_file_hash" ]; then
                    issues=$((issues + 1))
                    local escaped_file=$(echo "$file" | sed 's/"/\\"/g')
                    local context_json="{\"change_type\": \"modified\", \"file\": \"$escaped_file\", \"old_hash\": \"$baseline_file_hash\", \"new_hash\": \"$current_file_hash\"}"
                    write_event "cron_modification" "high" "cron_auditor" "$context_json"
                    log_auditor "cron_auditor" "WARNING" "System crontab modified: $file"
                fi
            fi
        done
    fi
    
    # Output JSON
    cat > "$AUDIT_OUTPUT" <<EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "audit_type": "cron",
  "issues_found": $issues,
  "findings": $findings,
  "crontab_modified": $([ "$current_hash" != "$baseline_hash" ] && echo "true" || echo "false")
}
EOF
    
    if [ $issues -eq 0 ]; then
        log_auditor "cron_auditor" "INFO" "Cron audit completed - no issues found"
    else
        log_auditor "cron_auditor" "WARNING" "Cron audit completed - $issues issue(s) found"
    fi
    
    return $issues
}

# Check privileges on load
if ! check_privileges "audit"; then
    log_auditor "cron_auditor" "WARNING" "Some cron audit checks may require sudo privileges"
fi

# Main execution
if [ "${1:-audit}" = "baseline" ]; then
    init_cron_baseline
else
    audit_cron_jobs
fi

