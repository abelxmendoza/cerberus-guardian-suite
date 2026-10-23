#!/bin/bash

# ===============================
# Enhanced Error Recovery System
# Auto-retry, graceful degradation, self-healing
# ===============================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Retry configuration
MAX_RETRIES="${MAX_RETRIES:-3}"
RETRY_DELAY="${RETRY_DELAY:-2}"  # seconds
MAX_RETRY_DELAY="${MAX_RETRY_DELAY:-30}"  # max delay with exponential backoff

# Execute with retry logic
execute_with_retry() {
    local description="$1"
    local max_attempts="${2:-$MAX_RETRIES}"
    shift 2
    local command="$*"
    
    local attempt=1
    local exit_code=1
    local last_error=""
    
    while [ $attempt -le $max_attempts ]; do
        if [ $attempt -gt 1 ]; then
            # Exponential backoff: delay = RETRY_DELAY * 2^(attempt-2)
            local delay=$((RETRY_DELAY * (2 ** (attempt - 2))))
            # Cap at max delay
            if [ $delay -gt $MAX_RETRY_DELAY ]; then
                delay=$MAX_RETRY_DELAY
            fi
            
            echo "⏳ Retrying $description (attempt $attempt/$max_attempts) in ${delay}s..."
            sleep $delay
        fi
        
        # Try to execute command
        set +e  # Don't exit on error
        eval "$command" 2>&1
        exit_code=$?
        set -e  # Re-enable exit on error
        
        if [ $exit_code -eq 0 ]; then
            if [ $attempt -gt 1 ]; then
                echo "✅ $description succeeded on retry (attempt $attempt)"
            fi
            return 0
        else
            last_error="Exit code: $exit_code"
            attempt=$((attempt + 1))
        fi
    done
    
    # All retries failed
    echo "❌ $description failed after $max_attempts attempts: $last_error" >&2
    return $exit_code
}

# Execute with graceful degradation
execute_with_fallback() {
    local primary_description="$1"
    local fallback_description="$2"
    shift 2
    local primary_command="$1"
    shift
    local fallback_command="$*"
    
    # Try primary command
    set +e
    eval "$primary_command" 2>&1
    local exit_code=$?
    set -e
    
    if [ $exit_code -eq 0 ]; then
        return 0
    fi
    
    # Primary failed, try fallback
    echo "⚠️  $primary_description failed, trying fallback: $fallback_description"
    set +e
    eval "$fallback_command" 2>&1
    exit_code=$?
    set -e
    
    if [ $exit_code -eq 0 ]; then
        echo "✅ Fallback succeeded: $fallback_description"
        return 0
    else
        echo "❌ Both primary and fallback failed" >&2
        return $exit_code
    fi
}

# Self-healing: Auto-fix common issues
auto_heal() {
    local error_type="$1"
    local error_context="${2:-}"
    
    case "$error_type" in
        permission_denied)
            echo "🔧 Auto-healing: Permission denied error"
            if [ -n "$error_context" ] && [ -f "$error_context" ]; then
                chmod +x "$error_context" 2>/dev/null && {
                    echo "✅ Fixed: Made $error_context executable"
                    return 0
                }
            fi
            ;;
        command_not_found)
            echo "🔧 Auto-healing: Command not found"
            local missing_cmd=$(echo "$error_context" | awk '{print $1}')
            if [ -n "$missing_cmd" ]; then
                # Try to install via brew
                if command -v brew &> /dev/null; then
                    echo "📦 Attempting to install $missing_cmd via Homebrew..."
                    brew install "$missing_cmd" 2>/dev/null && {
                        echo "✅ Fixed: Installed $missing_cmd"
                        return 0
                    }
                fi
            fi
            ;;
        network_error|connection_failed)
            echo "🔧 Auto-healing: Network error detected"
            # Wait and retry
            sleep 5
            return 2  # Signal to retry
            ;;
        disk_full)
            echo "🔧 Auto-healing: Disk space issue detected"
            # Try to free up space
            if command -v brew &> /dev/null; then
                brew cleanup 2>/dev/null || true
            fi
            # Clear temp files
            rm -rf /tmp/macguardian_* 2>/dev/null || true
            echo "✅ Attempted to free disk space"
            return 2  # Signal to retry
            ;;
        *)
            echo "ℹ️  No auto-heal available for: $error_type"
            return 1
            ;;
    esac
    
    return 1
}

# Smart error handler with recovery
smart_error_handler() {
    local exit_code=$1
    local line_no=$2
    local command="${3:-}"
    
    if [ $exit_code -eq 0 ]; then
        return 0
    fi
    
    # Determine error type
    local error_type="unknown"
    if echo "$command" | grep -qi "permission\|chmod\|access"; then
        error_type="permission_denied"
    elif echo "$command" | grep -qi "not found\|command not found"; then
        error_type="command_not_found"
    elif echo "$command" | grep -qi "network\|connection\|timeout\|refused"; then
        error_type="network_error"
    elif echo "$command" | grep -qi "disk\|space\|full\|quota"; then
        error_type="disk_full"
    fi
    
    # Try auto-healing
    local heal_result
    auto_heal "$error_type" "$command"
    heal_result=$?
    
    if [ $heal_result -eq 2 ]; then
        # Auto-heal suggests retry
        return 2
    elif [ $heal_result -eq 0 ]; then
        # Auto-heal succeeded
        return 0
    fi
    
    # Auto-heal couldn't fix it
    return $exit_code
}

# Execute with full recovery (retry + fallback + auto-heal)
execute_with_recovery() {
    local description="$1"
    shift
    local primary_command="$*"
    local fallback_command="${FALLBACK_COMMAND:-}"
    
    # First, try with retry
    if execute_with_retry "$description" "$MAX_RETRIES" "$primary_command"; then
        return 0
    fi
    
    # If retry failed and we have a fallback, try it
    if [ -n "$fallback_command" ]; then
        if execute_with_fallback "$description (primary)" "$description (fallback)" "$primary_command" "$fallback_command"; then
            return 0
        fi
    fi
    
    # All recovery attempts failed
    return 1
}

# Check system health before operations
check_system_health() {
    local issues=0
    
    # Check disk space
    local disk_usage=$(df -h "$HOME" | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$disk_usage" -gt 90 ]; then
        echo "⚠️  Warning: Disk usage is ${disk_usage}%"
        issues=$((issues + 1))
    fi
    
    # Check memory
    local mem_usage=$(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
    # Simple check - if free memory is very low
    if [ "${mem_usage:-0}" -lt 1000000 ]; then
        echo "⚠️  Warning: Low available memory"
        issues=$((issues + 1))
    fi
    
    # Check network connectivity
    if ! ping -c 1 -W 1 8.8.8.8 &> /dev/null; then
        echo "⚠️  Warning: Network connectivity issues"
        issues=$((issues + 1))
    fi
    
    if [ $issues -gt 0 ]; then
        echo "⚠️  System health check found $issues issue(s). Operations may be slower or fail."
        return 1
    fi
    
    return 0
}

# Main function
main() {
    case "${1:-}" in
        retry)
            shift
            execute_with_retry "$@"
            ;;
        fallback)
            shift
            execute_with_fallback "$@"
            ;;
        recover)
            shift
            execute_with_recovery "$@"
            ;;
        health)
            check_system_health
            ;;
        *)
            echo "Usage: error_recovery.sh [retry|fallback|recover|health] [args...]"
            ;;
    esac
}

# If run directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi

