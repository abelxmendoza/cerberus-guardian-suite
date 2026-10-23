#!/bin/bash

# ===============================
# Email Security Scanner
# Scans email attachments and detects phishing
# ===============================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"
source "$SCRIPT_DIR/config.sh"

# Email directories to scan
EMAIL_DIRS=(
    "$HOME/Library/Mail"
    "$HOME/.thunderbird"
    "$HOME/Library/Application Support/Microsoft/Outlook"
)

# Scan email attachments
scan_email_attachments() {
    local threats_found=0
    
    echo "${bold}📧 Scanning Email Attachments...${normal}"
    echo "----------------------------------------"
    
    if ! command -v clamscan &> /dev/null; then
        warning "ClamAV not found. Install with: brew install clamav"
        return 1
    fi
    
    for email_dir in "${EMAIL_DIRS[@]}"; do
        if [ ! -d "$email_dir" ]; then
            continue
        fi
        
        echo "Scanning: $email_dir"
        
        # Find and scan attachments
        local attachments=$(find "$email_dir" -type f \
            \( -name "*.exe" -o -name "*.dmg" -o -name "*.pkg" -o -name "*.zip" \
            -o -name "*.rar" -o -name "*.7z" -o -name "*.doc" -o -name "*.docx" \
            -o -name "*.xls" -o -name "*.xlsx" -o -name "*.ppt" -o -name "*.pptx" \
            -o -name "*.pdf" -o -name "*.js" -o -name "*.vbs" \) \
            2>/dev/null | head -100)
        
        if [ -n "$attachments" ]; then
            echo "$attachments" | while IFS= read -r file; do
                if [ -f "$file" ]; then
                    set +e
                    local scan_result=$(clamscan --no-summary "$file" 2>&1)
                    local exit_code=$?
                    set -e
                    
                    if [ $exit_code -eq 1 ]; then
                        warning "🚨 Threat found in email attachment: $file"
                        echo "$scan_result"
                        threats_found=$((threats_found + 1))
                        log_message "ALERT" "Email threat: $file"
                    fi
                fi
            done
        fi
    done
    
    if [ $threats_found -eq 0 ]; then
        success "No threats found in email attachments"
    else
        warning "Found $threats_found potential threat(s) in email attachments"
    fi
    
    return $threats_found
}

# Detect phishing URLs in emails
detect_phishing_urls() {
    local phishing_patterns=(
        "bit\.ly"
        "tinyurl\.com"
        "t\.co"
        "goo\.gl"
        "paypal.*login"
        "bank.*login"
        "verify.*account"
        "suspended.*account"
    )
    
    echo "${bold}🔍 Detecting Phishing URLs in Emails...${normal}"
    echo "----------------------------------------"
    
    local suspicious_emails=0
    
    for email_dir in "${EMAIL_DIRS[@]}"; do
        if [ ! -d "$email_dir" ]; then
            continue
        fi
        
        # Search email files for suspicious URLs
        for pattern in "${phishing_patterns[@]}"; do
            local matches=$(grep -r -i "$pattern" "$email_dir" 2>/dev/null | head -20 || true)
            
            if [ -n "$matches" ]; then
                warning "⚠️  Suspicious URL pattern found: $pattern"
                echo "$matches" | head -5
                suspicious_emails=$((suspicious_emails + 1))
            fi
        done
    done
    
    if [ $suspicious_emails -eq 0 ]; then
        success "No obvious phishing URLs detected"
    else
        warning "Found $suspicious_emails suspicious email(s) with potential phishing URLs"
    fi
    
    return $suspicious_emails
}

# Main function
main() {
    echo "${bold}📧 Email Security Scan${normal}"
    echo "=========================================="
    echo ""
    
    local total_threats=0
    
    scan_email_attachments
    total_threats=$((total_threats + $?))
    
    echo ""
    detect_phishing_urls
    total_threats=$((total_threats + $?))
    
    echo ""
    if [ $total_threats -eq 0 ]; then
        success "✅ Email security scan complete - No threats found"
    else
        warning "⚠️  Email security scan complete - $total_threats potential threat(s) found"
        send_notification "Email Security Alert" "Found $total_threats potential email threat(s)" "true" "critical"
    fi
}

main

