#!/bin/bash

# ===============================
# Diamond Model Correlation
# Analyzes adversary, infrastructure, capability, and victim
# ===============================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh" 2>/dev/null || true
source "$SCRIPT_DIR/config.sh" 2>/dev/null || true

DIAMOND_DB="${DIAMOND_DB:-$HOME/.macguardian/diamond_model.json}"
DIAMOND_DIR="${DIAMOND_DIR:-$HOME/.macguardian/diamond}"

mkdir -p "$(dirname "$DIAMOND_DB")" "$DIAMOND_DIR"

# Initialize Diamond Model database
init_diamond_db() {
    if [ ! -f "$DIAMOND_DB" ]; then
        cat > "$DIAMOND_DB" <<EOF
{
  "adversaries": [],
  "infrastructure": [],
  "capabilities": [],
  "victims": [],
  "events": []
}
EOF
        success "Diamond Model database initialized"
    fi
}

# Add adversary
add_adversary() {
    local adversary_id="$1"
    local name="${2:-Unknown}"
    local motivation="${3:-Unknown}"
    local capability="${4:-Unknown}"
    
    # Check if jq is available
    if ! command -v jq &> /dev/null; then
        warning "jq not installed. Install with: brew install jq"
        return 1
    fi
    
    local adversary=$(cat <<EOF
{
  "id": "$adversary_id",
  "name": "$name",
  "motivation": "$motivation",
  "capability": "$capability",
  "first_seen": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "last_seen": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
)
    
    # Add to database
    jq ".adversaries += [$adversary]" "$DIAMOND_DB" > "${DIAMOND_DB}.tmp" && mv "${DIAMOND_DB}.tmp" "$DIAMOND_DB"
    
    success "Adversary added: $name"
}

# Add infrastructure
add_infrastructure() {
    local infra_type="$1"  # ip, domain, url
    local value="$2"
    local malicious="${3:-true}"
    
    if ! command -v jq &> /dev/null; then
        warning "jq not installed"
        return 1
    fi
    
    local infra=$(cat <<EOF
{
  "type": "$infra_type",
  "value": "$value",
  "malicious": $malicious,
  "first_seen": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "last_seen": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
)
    
    jq ".infrastructure += [$infra]" "$DIAMOND_DB" > "${DIAMOND_DB}.tmp" && mv "${DIAMOND_DB}.tmp" "$DIAMOND_DB"
    
    success "Infrastructure added: $infra_type=$value"
}

# Add capability
add_capability() {
    local capability_type="$1"  # malware, tool, technique
    local name="$2"
    local description="${3:-}"
    
    if ! command -v jq &> /dev/null; then
        warning "jq not installed"
        return 1
    fi
    
    local capability=$(cat <<EOF
{
  "type": "$capability_type",
  "name": "$name",
  "description": "$description",
  "first_seen": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "last_seen": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
)
    
    jq ".capabilities += [$capability]" "$DIAMOND_DB" > "${DIAMOND_DB}.tmp" && mv "${DIAMOND_DB}.tmp" "$DIAMOND_DB"
    
    success "Capability added: $name"
}

# Add victim (system information)
add_victim() {
    local system_info="${1:-$(hostname)}"
    local impact="${2:-unknown}"
    
    if ! command -v jq &> /dev/null; then
        warning "jq not installed"
        return 1
    fi
    
    local victim=$(cat <<EOF
{
  "system": "$system_info",
  "impact": "$impact",
  "first_seen": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "last_seen": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
)
    
    jq ".victims += [$victim]" "$DIAMOND_DB" > "${DIAMOND_DB}.tmp" && mv "${DIAMOND_DB}.tmp" "$DIAMOND_DB"
    
    success "Victim added: $system_info"
}

# Correlate Diamond Model elements
correlate_diamond() {
    if [ ! -f "$DIAMOND_DB" ]; then
        init_diamond_db
    fi
    
    if ! command -v jq &> /dev/null; then
        warning "jq not installed. Install with: brew install jq"
        return 1
    fi
    
    echo "${bold}🔷 Diamond Model Correlation Analysis${normal}"
    echo "=========================================="
    echo ""
    
    # Count elements
    local adversaries=$(jq '.adversaries | length' "$DIAMOND_DB" 2>/dev/null || echo "0")
    local infrastructure=$(jq '.infrastructure | length' "$DIAMOND_DB" 2>/dev/null || echo "0")
    local capabilities=$(jq '.capabilities | length' "$DIAMOND_DB" 2>/dev/null || echo "0")
    local victims=$(jq '.victims | length' "$DIAMOND_DB" 2>/dev/null || echo "0")
    
    echo "Diamond Model Elements:"
    echo "  Adversaries: $adversaries"
    echo "  Infrastructure: $infrastructure"
    echo "  Capabilities: $capabilities"
    echo "  Victims: $victims"
    echo ""
    
    # Show correlations
    if [ "$adversaries" -gt 0 ] || [ "$infrastructure" -gt 0 ] || [ "$capabilities" -gt 0 ]; then
        echo "Recent Activity:"
        
        # Show recent infrastructure
        if [ "$infrastructure" -gt 0 ]; then
            echo ""
            echo "Infrastructure:"
            jq -r '.infrastructure[-5:] | .[] | "  • \(.type): \(.value) (malicious: \(.malicious))"' "$DIAMOND_DB" 2>/dev/null || true
        fi
        
        # Show recent capabilities
        if [ "$capabilities" -gt 0 ]; then
            echo ""
            echo "Capabilities:"
            jq -r '.capabilities[-5:] | .[] | "  • \(.type): \(.name)"' "$DIAMOND_DB" 2>/dev/null || true
        fi
    else
        info "No Diamond Model data yet. Run security scans to populate."
    fi
}

# Auto-populate from Blue Team results
populate_from_blueteam() {
    local blueteam_results="${1:-$HOME/.macguardian/blueteam/results_*.txt}"
    
    if ! command -v jq &> /dev/null; then
        warning "jq not installed. Install with: brew install jq"
        return 1
    fi
    
    init_diamond_db
    
    # Extract suspicious IPs from Blue Team results
    local suspicious_ips=$(grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" "$blueteam_results" 2>/dev/null | sort -u | head -10 || true)
    
    for ip in $suspicious_ips; do
        add_infrastructure "ip" "$ip" "true" 2>/dev/null || true
    done
    
    # Extract suspicious domains
    local suspicious_domains=$(grep -oE "[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}" "$blueteam_results" 2>/dev/null | sort -u | head -10 || true)
    
    for domain in $suspicious_domains; do
        # Skip common safe domains
        if echo "$domain" | grep -qiE "(apple|google|microsoft|github|stackoverflow)"; then
            continue
        fi
        add_infrastructure "domain" "$domain" "true" 2>/dev/null || true
    done
    
    # Extract capabilities (malware, tools)
    local malware_patterns=$(grep -iE "(malware|trojan|virus|backdoor|keylogger)" "$blueteam_results" 2>/dev/null | head -5 || true)
    
    if [ -n "$malware_patterns" ]; then
        add_capability "malware" "Detected Malware" "Malware detected in Blue Team scan" 2>/dev/null || true
    fi
    
    # Add current system as victim
    add_victim "$(hostname)" "monitored" 2>/dev/null || true
    
    success "Diamond Model populated from Blue Team results"
}

# Main function
main() {
    case "${1:-correlate}" in
        init)
            init_diamond_db
            ;;
        correlate)
            correlate_diamond
            ;;
        populate)
            populate_from_blueteam "${2:-}"
            ;;
        adversary)
            add_adversary "$2" "${3:-Unknown}" "${4:-Unknown}" "${5:-Unknown}"
            ;;
        infrastructure)
            add_infrastructure "$2" "$3" "${4:-true}"
            ;;
        capability)
            add_capability "$2" "$3" "${4:-}"
            ;;
        victim)
            add_victim "$2" "${3:-unknown}"
            ;;
        *)
            echo "Usage: $0 [init|correlate|populate|adversary|infrastructure|capability|victim] [args...]"
            ;;
    esac
}

# If run directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi

