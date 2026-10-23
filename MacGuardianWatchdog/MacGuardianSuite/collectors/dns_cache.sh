#!/bin/bash
# ===============================
# DNS Cache for Network Monitoring
# LRU cache for last 500 DNS lookups
# O(1) lookups, reduces DNS query overhead
# ===============================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUITE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

DNS_CACHE_FILE="$HOME/.macguardian/cache/dns_cache.json"
CACHE_SIZE=500

# Initialize cache
init_cache() {
    mkdir -p "$(dirname "$DNS_CACHE_FILE")"
    if [ ! -f "$DNS_CACHE_FILE" ]; then
        echo "{}" > "$DNS_CACHE_FILE"
    fi
}

# Get DNS resolution (with caching)
get_dns_resolution() {
    local ip="$1"
    
    # Check cache first
    local cached=$(jq -r ".[\"$ip\"] // empty" "$DNS_CACHE_FILE" 2>/dev/null || echo "")
    
    if [ -n "$cached" ]; then
        echo "$cached"
        return 0
    fi
    
    # Perform DNS lookup
    local hostname=$(dig +short -x "$ip" 2>/dev/null | head -1 | sed 's/\.$//' || echo "")
    
    if [ -z "$hostname" ]; then
        hostname="unknown"
    fi
    
    # Update cache
    update_cache "$ip" "$hostname"
    
    echo "$hostname"
}

# Update cache (LRU eviction)
update_cache() {
    local ip="$1"
    local hostname="$2"
    local timestamp=$(date +%s)
    
    # Load cache
    local cache=$(cat "$DNS_CACHE_FILE" 2>/dev/null || echo "{}")
    
    # Add new entry
    cache=$(echo "$cache" | jq ". + {\"$ip\": {\"hostname\": \"$hostname\", \"timestamp\": $timestamp}}")
    
    # Get cache size and evict oldest if needed
    local count=$(echo "$cache" | jq 'length')
    
    if [ "$count" -gt "$CACHE_SIZE" ]; then
        # Remove oldest entry
        local oldest_ip=$(echo "$cache" | jq -r 'to_entries | sort_by(.value.timestamp) | .[0].key')
        cache=$(echo "$cache" | jq "del(.[\"$oldest_ip\"])")
    fi
    
    # Save cache
    echo "$cache" > "$DNS_CACHE_FILE"
}

# Clear cache
clear_cache() {
    echo "{}" > "$DNS_CACHE_FILE"
}

# Get cache statistics
cache_stats() {
    local count=$(jq 'length' "$DNS_CACHE_FILE" 2>/dev/null || echo "0")
    echo "DNS Cache: $count entries"
}

# Main function
main() {
    local command="${1:-resolve}"
    local ip="${2:-}"
    
    init_cache
    
    case "$command" in
        "resolve")
            if [ -z "$ip" ]; then
                echo "Usage: dns_cache.sh resolve <ip>"
                exit 1
            fi
            get_dns_resolution "$ip"
            ;;
        "clear")
            clear_cache
            echo "DNS cache cleared"
            ;;
        "stats")
            cache_stats
            ;;
        *)
            echo "Usage: dns_cache.sh [resolve|clear|stats] [ip]"
            exit 1
            ;;
    esac
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi

