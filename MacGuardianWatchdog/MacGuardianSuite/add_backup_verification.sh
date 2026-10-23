#!/bin/bash

# ===============================
# Backup Verification
# Verifies Time Machine backups are working
# ===============================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"
source "$SCRIPT_DIR/config.sh"

# Check Time Machine status
verify_time_machine() {
    echo "${bold}💾 Backup Verification${normal}"
    echo "----------------------------------------"
    
    local issues=0
    
    # Check if Time Machine is running
    if tmutil status 2>/dev/null | grep -q "Running = 1"; then
        success "✅ Time Machine is active"
    else
        warning "⚠️  Time Machine may not be running"
        issues=$((issues + 1))
    fi
    
    # Check last backup time
    local last_backup=$(tmutil latestbackup 2>/dev/null || echo "")
    if [ -n "$last_backup" ]; then
        local backup_date=$(basename "$last_backup" | cut -d'.' -f1)
        local backup_timestamp=$(date -j -f "%Y-%m-%d-%H%M%S" "$backup_date" "+%s" 2>/dev/null || echo "0")
        local current_timestamp=$(date +%s)
        local days_since=$(( (current_timestamp - backup_timestamp) / 86400 ))
        
        if [ $days_since -lt 1 ]; then
            success "✅ Last backup: Today"
        elif [ $days_since -lt 7 ]; then
            info "ℹ️  Last backup: $days_since day(s) ago"
        else
            warning "⚠️  Last backup: $days_since day(s) ago (backup may be stale)"
            issues=$((issues + 1))
        fi
    else
        warning "⚠️  No Time Machine backups found"
        issues=$((issues + 1))
    fi
    
    # Check backup destination
    local destination=$(tmutil destinationinfo 2>/dev/null | grep -i "Name:" | head -1 | cut -d: -f2 | xargs)
    if [ -n "$destination" ]; then
        info "ℹ️  Backup destination: $destination"
    else
        warning "⚠️  No backup destination configured"
        issues=$((issues + 1))
    fi
    
    # Check backup size
    local backup_size=$(tmutil calculatedrift "$(tmutil latestbackup 2>/dev/null)" 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
    if [ "$backup_size" != "0" ] && [ -n "$backup_size" ]; then
        info "ℹ️  Backup size: $backup_size"
    fi
    
    # Verify backup integrity (check if latest backup is accessible)
    local latest_backup=$(tmutil latestbackup 2>/dev/null)
    if [ -n "$latest_backup" ] && [ -d "$latest_backup" ]; then
        if [ -r "$latest_backup" ]; then
            success "✅ Latest backup is accessible and readable"
        else
            warning "⚠️  Latest backup exists but may not be fully accessible"
            issues=$((issues + 1))
        fi
    fi
    
    echo ""
    if [ $issues -eq 0 ]; then
        success "✅ Backup verification complete - All checks passed"
        return 0
    else
        warning "⚠️  Backup verification complete - $issues issue(s) found"
        return $issues
    fi
}

# Main function
main() {
    verify_time_machine
}

main

