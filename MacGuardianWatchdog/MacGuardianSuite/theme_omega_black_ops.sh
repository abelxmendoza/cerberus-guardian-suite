#!/bin/bash
# Omega Tech Black-Ops Theme
# Centralized styling for the MacGuardian Watchdog suite

# Determine whether the terminal supports 256 colors
if command -v tput >/dev/null 2>&1; then
    OMEGA_TPUT_COLORS=$(tput colors 2>/dev/null || echo 0)
else
    OMEGA_TPUT_COLORS=0
fi

if [ "${OMEGA_TPUT_COLORS:-0}" -ge 256 ]; then
    OMEGA_BG_PRIMARY="\033[48;5;232m"
    OMEGA_FG_MAIN="\033[38;5;252m"
    OMEGA_FG_SUBTLE="\033[38;5;242m"
    OMEGA_ACCENT_PURPLE="\033[38;5;93m"
    OMEGA_ACCENT_RED="\033[38;5;196m"
    OMEGA_ACCENT_YELLOW="\033[38;5;226m"
    OMEGA_CRITICAL_BG="\033[48;5;52m\033[38;5;15m"
else
    OMEGA_BG_PRIMARY=""
    OMEGA_FG_MAIN="\033[37m"
    OMEGA_FG_SUBTLE="\033[90m"
    OMEGA_ACCENT_PURPLE="\033[35m"
    OMEGA_ACCENT_RED="\033[31m"
    OMEGA_ACCENT_YELLOW="\033[33m"
    OMEGA_CRITICAL_BG="\033[41m\033[97m"
fi

OMEGA_RESET="\033[0m"
OMEGA_BOLD="\033[1m"
OMEGA_DIM="\033[2m"

OMEGA_THEME_NAME="Omega Tech Black-Ops"
OMEGA_THEME_ID="omega_tech_black_ops"
OMEGA_PROMPT_GLIPH="Ω"
OMEGA_PROMPT_COLOR="${OMEGA_ACCENT_PURPLE}${OMEGA_BOLD}"

read -r -d '' OMEGA_ASCII_LOGO <<'LOGO'
███╗   ███╗ █████╗  ██████╗  █████╗     ████████╗███████╗ ██████╗██╗  ██╗
████╗ ████║██╔══██╗██╔════╝ ██╔══██╗    ╚══██╔══╝██╔════╝██╔════╝██║ ██╔╝
██╔████╔██║███████║██║  ███╗███████║       ██║   █████╗  ██║     █████╔╝ 
██║╚██╔╝██║██╔══██║██║   ██║██╔══██║       ██║   ██╔══╝  ██║     ██╔═██╗ 
██║ ╚═╝ ██║██║  ██║╚██████╔╝██║  ██║       ██║   ███████╗╚██████╗██║  ██╗
╚═╝     ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝       ╚═╝   ╚══════╝ ╚═════╝╚═╝  ╚═╝
               ▄▀█ █▀▄ █▀▀ ▄▀█ ▀█▀ █▀▀   ▀█▀ █▀▀ █▀▀ █░█
               █▀█ █▄▀ █▄▄ █▀█ ░█░ ██▄   ░█░ ██▄ █▄▄ █▀█
LOGO

omega_banner() {
    printf "${OMEGA_BG_PRIMARY}${OMEGA_BOLD}%b${OMEGA_RESET}\n" "${OMEGA_ACCENT_PURPLE}${OMEGA_ASCII_LOGO}${OMEGA_RESET}"
    printf "%b%s%b\n" "${OMEGA_ACCENT_RED}${OMEGA_BOLD}" "               O M E G A   T E C H   B L A C K - O P S   C O N S O L E" "${OMEGA_RESET}"
    printf "%b%s%b\n" "${OMEGA_FG_SUBTLE}" "──────────────────────────────────────────────────────────────────────────────" "${OMEGA_RESET}"
}

omega_divider() {
    printf "%b%s%b\n" "${OMEGA_FG_SUBTLE}" "──────────────────────────────────────────────────────────────────────────────" "${OMEGA_RESET}"
}

omega_echo() {
    local color="$1"
    shift
    printf "%b%s%b\n" "${color}" "$*" "${OMEGA_RESET}"
}

omega_status() {
    local level="$1"
    shift
    local message="$*"
    case "$level" in
        success)
            omega_echo "${OMEGA_ACCENT_PURPLE}${OMEGA_BOLD}" "[MISSION SUCCESS] ${message}"
            ;;
        info)
            omega_echo "${OMEGA_FG_MAIN}" "[INTEL] ${message}"
            ;;
        warn)
            omega_echo "${OMEGA_ACCENT_YELLOW}${OMEGA_BOLD}" "[WARNING] ${message}"
            ;;
        critical)
            omega_echo "${OMEGA_CRITICAL_BG}${OMEGA_BOLD}" "[CRITICAL] ${message}"
            ;;
        error)
            omega_echo "${OMEGA_ACCENT_RED}${OMEGA_BOLD}" "[ERROR] ${message}"
            ;;
        *)
            omega_echo "${OMEGA_FG_MAIN}" "${message}"
            ;;
    esac
}

omega_prompt_text() {
    printf "%b%s%b" "${OMEGA_PROMPT_COLOR}" "$1" "${OMEGA_RESET}"
}

omega_menu_option() {
    local number="$1"
    local label="$2"
    printf "%b%2s%b %b%s%b\n" "${OMEGA_ACCENT_PURPLE}${OMEGA_BOLD}" "$number" "${OMEGA_RESET}" "${OMEGA_FG_MAIN}" "$label" "${OMEGA_RESET}"
}

omega_menu_section() {
    omega_echo "${OMEGA_ACCENT_YELLOW}${OMEGA_BOLD}" "$1"
    omega_divider
}

omega_label_value() {
    local label="$1"
    local value="$2"
    printf "%b%s%b %b%s%b\n" "${OMEGA_FG_SUBTLE}${OMEGA_BOLD}" "$label" "${OMEGA_RESET}" "${OMEGA_FG_MAIN}" "$value" "${OMEGA_RESET}"
}

# shellcheck disable=SC2034
OMEGA_THEME_DOCS=(
    "Palette: #0D0D0D background, #8C00FF purple, #FF1100 red, #FFE600 yellow, #E5E5E5 text"
    "Usage: source this file to style menu outputs and alerts"
)
