#!/bin/bash

# ===============================
# UX Enhancement System
# Progress bars, time estimates, better messages
# ===============================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
bold=$(tput bold 2>/dev/null || echo "")
normal=$(tput sgr0 2>/dev/null || echo "")
green=$(tput setaf 2 2>/dev/null || echo "")
yellow=$(tput setaf 3 2>/dev/null || echo "")
blue=$(tput setaf 4 2>/dev/null || echo "")
cyan=$(tput setaf 6 2>/dev/null || echo "")

# Progress bar
show_progress() {
    local current=$1
    local total=$2
    local width=${3:-50}
    local label="${4:-Progress}"
    
    local percent=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    # Build progress bar
    local bar=""
    local i=0
    while [ $i -lt $filled ]; do
        bar="${bar}█"
        i=$((i + 1))
    done
    while [ $i -lt $width ]; do
        bar="${bar}░"
        i=$((i + 1))
    done
    
    # Print progress
    printf "\r${cyan}%s${normal} [${green}%s${normal}] %d%% (%d/%d)" "$label" "$bar" "$percent" "$current" "$total"
    
    if [ $current -eq $total ]; then
        echo ""  # New line when complete
    fi
}

# Spinner for indeterminate progress
show_spinner() {
    local pid=$1
    local message="${2:-Processing...}"
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        i=$(((i + 1) % 10))
        printf "\r${cyan}%s${normal} ${spin:$i:1}" "$message"
        sleep 0.1
    done
    printf "\r${green}✅${normal} %s\n" "$message"
}

# Estimated time remaining
estimate_time() {
    local operation_name="$1"
    local completed=$2
    local total=$3
    local start_time=$4
    
    if [ $completed -eq 0 ]; then
        echo "Estimating..."
        return
    fi
    
    local current_time=$(date +%s)
    local elapsed=$((current_time - start_time))
    local rate=$((elapsed / completed))
    local remaining=$((rate * (total - completed)))
    
    # Format time
    if [ $remaining -lt 60 ]; then
        echo "${remaining}s remaining"
    elif [ $remaining -lt 3600 ]; then
        local mins=$((remaining / 60))
        echo "${mins}m ${remaining}s remaining"
    else
        local hours=$((remaining / 3600))
        local mins=$(((remaining % 3600) / 60))
        echo "${hours}h ${mins}m remaining"
    fi
}

# Better error messages with solutions
format_error() {
    local error_code=$1
    local error_message="$2"
    local context="${3:-}"
    
    case $error_code in
        1)
            echo "${red}❌ Error: $error_message${normal}"
            if echo "$error_message" | grep -qi "permission"; then
                echo "${yellow}💡 Solution: Try running with sudo or check file permissions${normal}"
            fi
            ;;
        2)
            echo "${red}❌ Error: $error_message${normal}"
            if echo "$error_message" | grep -qi "not found\|command not found"; then
                local missing=$(echo "$error_message" | grep -oE "[a-z-]+: command not found" | cut -d: -f1)
                if [ -n "$missing" ]; then
                    echo "${yellow}💡 Solution: Install missing command: brew install $missing${normal}"
                fi
            fi
            ;;
        126)
            echo "${red}❌ Error: Command cannot execute${normal}"
            echo "${yellow}💡 Solution: Check if file is executable: chmod +x $context${normal}"
            ;;
        127)
            echo "${red}❌ Error: Command not found${normal}"
            echo "${yellow}💡 Solution: Install the required tool or check your PATH${normal}"
            ;;
        *)
            echo "${red}❌ Error: $error_message (code: $error_code)${normal}"
            if [ -n "$context" ]; then
                echo "${yellow}💡 Context: $context${normal}"
            fi
            ;;
    esac
}

# Interactive confirmation with better UX
confirm_action() {
    local message="$1"
    local default="${2:-n}"
    
    if [ "$default" = "y" ]; then
        local prompt="${green}[Y/n]${normal}"
    else
        local prompt="${yellow}[y/N]${normal}"
    fi
    
    echo -n "${bold}$message $prompt: ${normal}"
    read -r response
    
    if [ -z "$response" ]; then
        response="$default"
    fi
    
    [[ "$response" =~ ^[Yy]$ ]]
}

# Step indicator
show_step() {
    local step_num=$1
    local total_steps=$2
    local step_name="$3"
    
    echo ""
    echo "${bold}${cyan}[$step_num/$total_steps]${normal} ${bold}$step_name${normal}"
    echo "----------------------------------------"
}

# Status message with icon
status_message() {
    local status="$1"  # success, warning, error, info
    local message="$2"
    
    case "$status" in
        success)
            echo "${green}✅ $message${normal}"
            ;;
        warning)
            echo "${yellow}⚠️  $message${normal}"
            ;;
        error)
            echo "${red}❌ $message${normal}"
            ;;
        info)
            echo "${blue}ℹ️  $message${normal}"
            ;;
        *)
            echo "$message"
            ;;
    esac
}

# Loading indicator
show_loading() {
    local message="$1"
    local pid=$2
    
    show_spinner "$pid" "$message" &
    local spinner_pid=$!
    
    wait $pid
    local exit_code=$?
    
    kill $spinner_pid 2>/dev/null || true
    wait $spinner_pid 2>/dev/null || true
    
    return $exit_code
}

# Countdown timer
countdown() {
    local seconds=$1
    local message="${2:-Starting in}"
    
    while [ $seconds -gt 0 ]; do
        printf "\r${yellow}%s %d...${normal}" "$message" "$seconds"
        sleep 1
        seconds=$((seconds - 1))
    done
    printf "\r${green}✅ Starting now!${normal}\n"
}

# Main function
main() {
    case "${1:-}" in
        progress)
            show_progress "$2" "$3" "${4:-50}" "${5:-Progress}"
            ;;
        spinner)
            show_spinner "$2" "${3:-Processing...}"
            ;;
        error)
            format_error "$2" "$3" "${4:-}"
            ;;
        confirm)
            confirm_action "$2" "${3:-n}"
            ;;
        step)
            show_step "$2" "$3" "$4"
            ;;
        status)
            status_message "$2" "$3"
            ;;
        *)
            echo "Usage: ux_enhancer.sh [progress|spinner|error|confirm|step|status] [args...]"
            ;;
    esac
}

# If run directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi

