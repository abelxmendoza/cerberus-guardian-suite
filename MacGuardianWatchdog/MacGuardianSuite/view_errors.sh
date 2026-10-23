#!/bin/bash

# ===============================
# Error Viewer & Fixer
# View and fix tracked errors
# ===============================

set -euo pipefail

# Set TERM if not set (required for tput)
export TERM="${TERM:-xterm-256color}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"
source "$SCRIPT_DIR/error_tracker.sh" 2>/dev/null || {
    error_exit "Error tracker not available"
}

# Colors (already defined in utils.sh, but define here as fallback)
bold="${bold:-$(tput bold 2>/dev/null || echo "")}"
normal="${normal:-$(tput sgr0 2>/dev/null || echo "")}"
green="${green:-$(tput setaf 2 2>/dev/null || echo "")}"
red="${red:-$(tput setaf 1 2>/dev/null || echo "")}"
yellow="${yellow:-$(tput setaf 3 2>/dev/null || echo "")}"
cyan="${cyan:-$(tput setaf 6 2>/dev/null || echo "")}"

# Display errors in a readable format
display_errors() {
    local errors="$1"
    local count=0
    
    if [ -z "$errors" ]; then
        echo "${green}✅ No errors found!${normal}"
        return 0
    fi
    
    echo "$errors" | while IFS= read -r line; do
        if [ -z "$line" ]; then
            continue
        fi
        
        # Try to parse JSON, fallback to text display
        if command -v python3 &> /dev/null; then
            python3 <<PYEOF 2>/dev/null || echo "$line"
import json
import sys

try:
    error = json.loads("$line")
    count = $count + 1
    print(f"\n${bold}Error #{count}${normal}")
    print(f"  ${cyan}ID:${normal} {error.get('id', 'unknown')}")
    print(f"  ${cyan}Time:${normal} {error.get('timestamp', 'unknown')}")
    print(f"  ${cyan}Script:${normal} {error.get('script', 'unknown')}:{error.get('line', '0')}")
    print(f"  ${cyan}Type:${normal} {error.get('type', 'unknown')}")
    print(f"  ${cyan}Severity:${normal} {error.get('severity', 'unknown')}")
    print(f"  ${cyan}Message:${normal} {error.get('message', 'unknown')}")
    if error.get('fixable') == 'true':
        print(f"  ${green}✅ Fixable${normal}")
        if error.get('fix_command'):
            print(f"  ${green}Fix:${normal} {error.get('fix_command')}")
    else:
        print(f"  ${yellow}⚠️  Not auto-fixable${normal}")
except:
    print("$line")
PYEOF
        else
            echo "$line"
        fi
    done
}

# Main menu
main() {
    while true; do
        clear
        echo "${bold}=========================================="
        echo "🔍 Error Viewer & Fixer"
        echo "==========================================${normal}"
        echo ""
        
        # Show summary
        show_error_summary
        echo ""
        echo "1) View all unresolved errors"
        echo "2) View critical errors"
        echo "3) View high severity errors"
        echo "4) View auto-fixable errors"
        echo "5) Auto-fix all fixable errors"
        echo "6) View error statistics"
        echo "7) Clear resolved errors"
        echo "8) Exit"
        echo ""
        read -p "Select (1-8): " choice
        
        case "$choice" in
            1)
                echo ""
                echo "${bold}All Unresolved Errors:${normal}"
                echo "----------------------------------------"
                display_errors "$(get_unresolved_errors)"
                echo ""
                read -p "Press Enter to continue..."
                ;;
            2)
                echo ""
                echo "${bold}Critical Errors:${normal}"
                echo "----------------------------------------"
                display_errors "$(get_errors_by_severity critical)"
                echo ""
                read -p "Press Enter to continue..."
                ;;
            3)
                echo ""
                echo "${bold}High Severity Errors:${normal}"
                echo "----------------------------------------"
                display_errors "$(get_errors_by_severity high)"
                echo ""
                read -p "Press Enter to continue..."
                ;;
            4)
                echo ""
                echo "${bold}Auto-Fixable Errors:${normal}"
                echo "----------------------------------------"
                local fixable=$(get_fixable_errors)
                display_errors "$fixable"
                if [ -n "$fixable" ]; then
                    echo ""
                    read -p "Would you like to auto-fix these errors? (y/n): " confirm
                    if [[ "$confirm" =~ ^[Yy]$ ]]; then
                        echo "$fixable" | while IFS= read -r line; do
                            if [ -z "$line" ]; then
                                continue
                            fi
                            if command -v python3 &> /dev/null; then
                                local error_id=$(python3 -c "import json, sys; error = json.loads('$line'); print(error.get('id', ''))" 2>/dev/null || echo "")
                                if [ -n "$error_id" ]; then
                                    if auto_fix_error "$error_id"; then
                                        echo "${green}✅ Fixed error: $error_id${normal}"
                                    else
                                        echo "${yellow}⚠️  Could not auto-fix: $error_id${normal}"
                                    fi
                                fi
                            fi
                        done
                    fi
                fi
                echo ""
                read -p "Press Enter to continue..."
                ;;
            5)
                echo ""
                echo "${bold}Auto-Fixing All Fixable Errors...${normal}"
                echo "----------------------------------------"
                local fixable=$(get_fixable_errors)
                local fixed=0
                local failed=0
                
                if [ -z "$fixable" ]; then
                    echo "${green}✅ No fixable errors found.${normal}"
                else
                    echo "$fixable" | while IFS= read -r line; do
                        if [ -z "$line" ]; then
                            continue
                        fi
                        if command -v python3 &> /dev/null; then
                            local error_id=$(python3 -c "import json, sys; error = json.loads('$line'); print(error.get('id', ''))" 2>/dev/null || echo "")
                            if [ -n "$error_id" ]; then
                                if auto_fix_error "$error_id"; then
                                    echo "${green}✅ Fixed: $error_id${normal}"
                                    fixed=$((fixed + 1))
                                else
                                    echo "${yellow}⚠️  Failed: $error_id${normal}"
                                    failed=$((failed + 1))
                                fi
                            fi
                        fi
                    done
                    echo ""
                    echo "${green}Fixed: $fixed${normal}"
                    if [ $failed -gt 0 ]; then
                        echo "${yellow}Failed: $failed${normal}"
                    fi
                fi
                echo ""
                read -p "Press Enter to continue..."
                ;;
            6)
                echo ""
                echo "${bold}Error Statistics:${normal}"
                echo "----------------------------------------"
                if [ -f "$ERROR_STATS" ]; then
                    echo "Error counts by type and severity:"
                    echo ""
                    cat "$ERROR_STATS" | sort | uniq -c | sort -rn | head -20 || cat "$ERROR_STATS"
                else
                    echo "No statistics available yet."
                fi
                echo ""
                read -p "Press Enter to continue..."
                ;;
            7)
                echo ""
                echo "${bold}Clearing Resolved Errors...${normal}"
                echo "----------------------------------------"
                read -p "This will remove all resolved errors from the database. Continue? (y/n): " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    if command -v python3 &> /dev/null; then
                        python3 <<PYEOF 2>/dev/null
import json
import sys

try:
    with open("$ERROR_DB", "r") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                error = json.loads(line)
                if error.get("status") != "resolved":
                    print(line)
            except:
                pass
except:
    pass
PYEOF
                        > "$ERROR_DB.tmp" && mv "$ERROR_DB.tmp" "$ERROR_DB" 2>/dev/null || true
                        echo "${green}✅ Resolved errors cleared.${normal}"
                    else
                        echo "${yellow}⚠️  Python3 required for this operation.${normal}"
                    fi
                fi
                echo ""
                read -p "Press Enter to continue..."
                ;;
            8)
                echo ""
                echo "${green}👋 Goodbye!${normal}"
                exit 0
                ;;
            *)
                echo "${red}❌ Invalid option.${normal}"
                sleep 1
                ;;
        esac
    done
}

main

