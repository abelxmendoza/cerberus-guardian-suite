#!/bin/bash

# ===============================
# Performance Monitoring System
# Tracks execution times and identifies bottlenecks
# ===============================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PERF_DB="${PERF_DB:-$HOME/.macguardian/performance.db}"
PERF_LOG="${PERF_LOG:-$HOME/.macguardian/logs/performance.log}"

mkdir -p "$(dirname "$PERF_DB")" "$(dirname "$PERF_LOG")"

# Start performance tracking
perf_start() {
    local operation_name="$1"
    local start_time=$(date +%s.%N)
    local pid=$$
    
    # Store start time in a temp file (PID-based for parallel operations)
    echo "$start_time" > "/tmp/macguardian_perf_${pid}_${operation_name}.tmp"
    
    export MACGUARDIAN_PERF_START_${operation_name//[^a-zA-Z0-9]/_}=$start_time
}

# End performance tracking
perf_end() {
    local operation_name="$1"
    local end_time=$(date +%s.%N)
    local pid=$$
    local start_file="/tmp/macguardian_perf_${pid}_${operation_name}.tmp"
    
    if [ -f "$start_file" ]; then
        local start_time=$(cat "$start_file")
        local duration=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "0")
        local duration_ms=$(echo "$duration * 1000" | bc 2>/dev/null || echo "0")
        
        # Log performance data
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        echo "$timestamp|$operation_name|$duration|$duration_ms" >> "$PERF_LOG"
        
        # Store in database (simple JSON format)
        local perf_entry=$(cat <<EOF
{
  "timestamp": "$timestamp",
  "operation": "$operation_name",
  "duration_seconds": $duration,
  "duration_ms": $duration_ms,
  "pid": $pid
}
EOF
)
        echo "$perf_entry" >> "$PERF_DB"
        
        # Cleanup
        rm -f "$start_file"
        
        echo "$duration_ms"
    else
        echo "0"
    fi
}

# Get performance statistics
perf_stats() {
    local operation_name="${1:-}"
    local days="${2:-7}"
    
    if [ ! -f "$PERF_DB" ]; then
        echo "No performance data available"
        return 1
    fi
    
    # Filter by operation if specified
    local filter=""
    if [ -n "$operation_name" ]; then
        filter="grep \"$operation_name\""
    else
        filter="cat"
    fi
    
    # Calculate stats using jq if available, otherwise simple parsing
    if command -v jq &> /dev/null; then
        local avg=$(tail -100 "$PERF_DB" | $filter | jq -r '.duration_ms' 2>/dev/null | awk '{sum+=$1; count++} END {if(count>0) print sum/count; else print 0}')
        local min=$(tail -100 "$PERF_DB" | $filter | jq -r '.duration_ms' 2>/dev/null | awk 'BEGIN{min=999999} {if($1<min) min=$1} END {print min}')
        local max=$(tail -100 "$PERF_DB" | $filter | jq -r '.duration_ms' 2>/dev/null | awk 'BEGIN{max=0} {if($1>max) max=$1} END {print max}')
        local count=$(tail -100 "$PERF_DB" | $filter | jq -r '.operation' 2>/dev/null | wc -l | tr -d ' ')
    else
        # Fallback: simple parsing
        local avg="0"
        local min="0"
        local max="0"
        local count="0"
    fi
    
    echo "Operation: ${operation_name:-All}"
    echo "Count: $count"
    echo "Average: ${avg}ms"
    echo "Min: ${min}ms"
    echo "Max: ${max}ms"
}

# Identify bottlenecks
identify_bottlenecks() {
    if [ ! -f "$PERF_DB" ] || [ ! -s "$PERF_DB" ]; then
        echo "ℹ️  No performance data available yet"
        echo "   Run Mac Guardian or other tools to collect performance data"
        echo "   Performance tracking is automatic - no setup needed!"
        return 1
    fi
    
    echo "🔍 Performance Bottlenecks Analysis"
    echo "=========================================="
    echo ""
    
    # Find slowest operations (if jq available)
    if command -v jq &> /dev/null; then
        echo "Slowest Operations:"
        tail -100 "$PERF_DB" | jq -r 'select(.duration_ms > 1000) | "\(.operation): \(.duration_ms)ms"' 2>/dev/null | sort -t: -k2 -nr | head -10
        echo ""
        
        echo "Operations Taking > 5 seconds:"
        tail -100 "$PERF_DB" | jq -r 'select(.duration_ms > 5000) | "\(.operation): \(.duration_ms)ms"' 2>/dev/null | wc -l | xargs echo
    else
        echo "Install 'jq' for detailed bottleneck analysis: brew install jq"
    fi
}

# Performance wrapper function
perf_wrap() {
    local operation_name="$1"
    shift
    local command="$*"
    
    perf_start "$operation_name"
    local exit_code=0
    eval "$command" || exit_code=$?
    local duration=$(perf_end "$operation_name")
    
    # Log if operation took longer than expected
    local threshold_ms=5000  # 5 seconds
    if [ -n "$duration" ] && [ "${duration%.*}" -gt "$threshold_ms" ] 2>/dev/null; then
        echo "⚠️  Performance: $operation_name took ${duration}ms (threshold: ${threshold_ms}ms)" >&2
    fi
    
    return $exit_code
}

# Get optimization suggestions
get_optimization_suggestions() {
    echo "💡 Performance Optimization Suggestions"
    echo "=========================================="
    echo ""
    
    if [ ! -f "$PERF_DB" ] || [ ! -s "$PERF_DB" ]; then
        echo "ℹ️  No performance data available yet"
        echo "   Performance tracking starts automatically when you run:"
        echo "   • Mac Guardian (option 1)"
        echo "   • Mac Watchdog (option 2)"
        echo "   • Mac Blue Team (option 3)"
        echo "   • Any other security tools"
        echo ""
        echo "   After running these tools, come back here to see optimization suggestions!"
        return 1
    fi
    
    # Check for common bottlenecks
    if command -v jq &> /dev/null; then
        # Find frequently slow operations
        local slow_ops=$(tail -100 "$PERF_DB" | jq -r 'select(.duration_ms > 3000) | .operation' 2>/dev/null | sort | uniq -c | sort -rn | head -5)
        
        if [ -n "$slow_ops" ]; then
            echo "⚠️  Slow Operations Detected:"
            echo "$slow_ops" | while read count op; do
                echo "  • $op: $count slow execution(s)"
                case "$op" in
                    *scan*|*clamav*)
                        echo "    → Suggestion: Use fast scan mode (already enabled) or reduce scan scope"
                        ;;
                    *find*|*filesystem*)
                        echo "    → Suggestion: Add more exclusions or reduce search depth"
                        ;;
                    *network*)
                        echo "    → Suggestion: Cache network results or reduce check frequency"
                        ;;
                    *)
                        echo "    → Suggestion: Consider parallel processing or optimization"
                        ;;
                esac
            done
        else
            echo "✅ No significant bottlenecks detected!"
        fi
    else
        echo "Install 'jq' for optimization suggestions: brew install jq"
    fi
}

# Main function
main() {
    case "${1:-stats}" in
        start)
            perf_start "${2:-}"
            ;;
        end)
            perf_end "${2:-}"
            ;;
        stats)
            perf_stats "${2:-}" "${3:-}"
            ;;
        bottlenecks)
            identify_bottlenecks
            ;;
        suggestions)
            get_optimization_suggestions
            ;;
        *)
            echo "Usage: performance_monitor.sh [start|end|stats|bottlenecks|suggestions] [operation_name]"
            ;;
    esac
}

# If run directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi

