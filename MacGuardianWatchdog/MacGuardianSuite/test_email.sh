#!/bin/bash

# ===============================
# Email Test Script
# Tests email sending functionality
# ===============================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"
source "$SCRIPT_DIR/config.sh"

# Load SMTP credentials from ~/.zshrc if not already set
if [ -z "${SMTP_USERNAME:-}" ] || [ -z "${SMTP_PASSWORD:-}" ]; then
    if [ -f ~/.zshrc ]; then
        # Extract SMTP credentials from ~/.zshrc
        eval $(grep "^export SMTP_USERNAME=" ~/.zshrc 2>/dev/null || true)
        eval $(grep "^export SMTP_PASSWORD=" ~/.zshrc 2>/dev/null || true)
    fi
fi

# Colors
bold=$(tput bold 2>/dev/null || echo "")
normal=$(tput sgr0 2>/dev/null || echo "")
green=$(tput setaf 2 2>/dev/null || echo "")
red=$(tput setaf 1 2>/dev/null || echo "")
yellow=$(tput setaf 3 2>/dev/null || echo "")
cyan=$(tput setaf 6 2>/dev/null || echo "")

echo "${bold}📧 Testing Email Functionality${normal}"
echo "=========================================="
echo ""

# Source email helper
if [ -f "$SCRIPT_DIR/email_helper.sh" ]; then
    source "$SCRIPT_DIR/email_helper.sh"
fi

# Check email configuration first
echo "${bold}📋 Checking Email Configuration...${normal}"
echo "----------------------------------------"
check_email_config 2>/dev/null || true
echo ""

# Get email address
TEST_EMAIL="${1:-${REPORT_EMAIL:-${ALERT_EMAIL:-}}}"

if [ -z "$TEST_EMAIL" ]; then
    read -p "Enter email address to test: " TEST_EMAIL
fi

if [ -z "$TEST_EMAIL" ]; then
    error_exit "No email address provided"
fi

echo ""
echo "Testing email to: ${cyan}$TEST_EMAIL${normal}"
echo ""

# Test 1: Check mail command
echo "${bold}Test 1: Checking mail command...${normal}"
if command -v mail &> /dev/null; then
    echo "${green}✅ mail command found${normal}"
    mail_version=$(mail -V 2>&1 | head -1 || echo "unknown")
    echo "   Version: $mail_version"
else
    echo "${red}❌ mail command not found${normal}"
    echo "   Install with: brew install mailutils"
fi
echo ""

# Test 2: Check sendmail
echo "${bold}Test 2: Checking sendmail...${normal}"
if command -v sendmail &> /dev/null; then
    echo "${green}✅ sendmail found${normal}"
    sendmail_path=$(which sendmail)
    echo "   Path: $sendmail_path"
else
    echo "${yellow}⚠️  sendmail not found${normal}"
fi
echo ""

# Test 3: Test Python SMTP (most reliable)
echo "${bold}Test 3: Sending test email via Python SMTP...${normal}"
if command -v python3 &> /dev/null && [ -f "$SCRIPT_DIR/send_email.py" ]; then
    if [ -n "${SMTP_USERNAME:-}" ] && [ -n "${SMTP_PASSWORD:-}" ]; then
        test_subject="MacGuardian Test Email (SMTP) - $(date '+%Y-%m-%d %H:%M:%S')"
        test_body="This is a test email from MacGuardian Suite (SMTP method).

If you received this email, your SMTP configuration is working correctly!

Test Details:
- Time: $(date)
- System: $(hostname)
- macOS: $(sw_vers -productVersion)
- Email Method: Python SMTP (Gmail)
- SMTP Server: smtp.gmail.com

This email was sent as part of the MacGuardian Suite email functionality test.
"
        
        if python3 "$SCRIPT_DIR/send_email.py" "$TEST_EMAIL" "$test_subject" "$test_body" --username "$SMTP_USERNAME" --password "$SMTP_PASSWORD" 2>&1; then
            echo "${green}✅ Email sent successfully via Python SMTP${normal}"
            echo "   Check your inbox: $TEST_EMAIL"
            PYTHON_SMTP_SUCCESS=true
        else
            echo "${red}❌ Failed to send email via Python SMTP${normal}"
            PYTHON_SMTP_SUCCESS=false
        fi
    else
        echo "${yellow}⚠️  SMTP credentials not configured${normal}"
        echo "   Set SMTP_USERNAME and SMTP_PASSWORD environment variables"
        PYTHON_SMTP_SUCCESS=false
    fi
else
    echo "${yellow}⚠️  Python SMTP sender not available${normal}"
    PYTHON_SMTP_SUCCESS=false
fi
echo ""

# Test 4: Test mail command (fallback - may not work on macOS)
echo "${bold}Test 4: Sending test email via mail command...${normal}"
echo "${yellow}⚠️  Note: mail command on macOS may not actually send emails${normal}"
echo "   It often just queues them locally. Use SMTP for reliable delivery."
if command -v mail &> /dev/null; then
    test_subject="MacGuardian Test Email (mail) - $(date '+%Y-%m-%d %H:%M:%S')"
    test_body="This is a test email from MacGuardian Suite (mail command).

Note: On macOS, the mail command may not actually send emails.
Use Python SMTP for reliable email delivery.

Test Details:
- Time: $(date)
- System: $(hostname)
- Email Method: mail command (may not work)
"
    
    if echo "$test_body" | mail -s "$test_subject" "$TEST_EMAIL" 2>&1; then
        echo "${yellow}⚠️  mail command reported success, but email may not actually be sent${normal}"
        echo "   Check your inbox, but don't rely on this method"
        MAIL_SUCCESS=false
    else
        echo "${red}❌ Failed to send email via mail command${normal}"
        MAIL_SUCCESS=false
    fi
else
    echo "${yellow}⚠️  Skipping (mail command not available)${normal}"
    MAIL_SUCCESS=false
fi
echo ""

# Test 5: Test sendmail (fallback)
echo "${bold}Test 5: Sending test email via sendmail...${normal}"
if command -v sendmail &> /dev/null; then
    test_subject="MacGuardian Test Email (sendmail) - $(date '+%Y-%m-%d %H:%M:%S')"
    {
        echo "To: $TEST_EMAIL"
        echo "Subject: $test_subject"
        echo "Content-Type: text/plain; charset=UTF-8"
        echo ""
        echo "This is a test email from MacGuardian Suite (sendmail method)."
        echo ""
        echo "If you received this email, your email configuration is working correctly!"
        echo ""
        echo "Test Details:"
        echo "- Time: $(date)"
        echo "- System: $(hostname)"
        echo "- macOS: $(sw_vers -productVersion)"
        echo "- Email Method: sendmail"
        echo ""
        echo "This email was sent as part of the MacGuardian Suite email functionality test."
    } | sendmail "$TEST_EMAIL" 2>&1 && {
        echo "${green}✅ Email sent successfully via sendmail${normal}"
        echo "   Check your inbox: $TEST_EMAIL"
        SENDMAIL_SUCCESS=true
    } || {
        echo "${red}❌ Failed to send email via sendmail${normal}"
        SENDMAIL_SUCCESS=false
    }
else
    echo "${yellow}⚠️  Skipping (sendmail not available)${normal}"
    SENDMAIL_SUCCESS=false
fi
echo ""

# Test 6: Test report email function
echo "${bold}Test 6: Testing report email function...${normal}"
if [ -f "$SCRIPT_DIR/scheduled_reports.sh" ]; then
    # Create a test report
    TEST_REPORT="/tmp/macguardian_test_report.html"
    cat > "$TEST_REPORT" <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>MacGuardian Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; padding: 20px; }
        h1 { color: #007aff; }
    </style>
</head>
<body>
    <h1>MacGuardian Test Report</h1>
    <p>This is a test HTML report to verify email functionality.</p>
    <p>Time: $(date)</p>
    <p>System: $(hostname)</p>
</body>
</html>
EOF
    
    # Source the report script and test
    source "$SCRIPT_DIR/scheduled_reports.sh" 2>/dev/null || true
    if type send_report_email &> /dev/null; then
        export REPORT_EMAIL="$TEST_EMAIL"
        if send_report_email "$TEST_REPORT" 2>&1; then
            echo "${green}✅ Report email function works${normal}"
        else
            echo "${yellow}⚠️  Report email function had issues${normal}"
        fi
    else
        echo "${yellow}⚠️  send_report_email function not available${normal}"
    fi
    rm -f "$TEST_REPORT"
else
    echo "${yellow}⚠️  scheduled_reports.sh not found${normal}"
fi
echo ""

# Test 7: Test alert email function
echo "${bold}Test 7: Testing alert email function...${normal}"
if [ -f "$SCRIPT_DIR/advanced_alerting.sh" ]; then
    source "$SCRIPT_DIR/advanced_alerting.sh" 2>/dev/null || true
    if type send_alert_email &> /dev/null; then
        export ALERT_EMAIL="$TEST_EMAIL"
        if send_alert_email "test_rule" "medium" 2>&1; then
            echo "${green}✅ Alert email function works${normal}"
        else
            echo "${yellow}⚠️  Alert email function had issues${normal}"
        fi
    else
        echo "${yellow}⚠️  send_alert_email function not available${normal}"
    fi
else
    echo "${yellow}⚠️  advanced_alerting.sh not found${normal}"
fi
echo ""

# Summary
echo "${bold}📊 Test Summary${normal}"
echo "=========================================="
echo ""
echo "Email Address: ${cyan}$TEST_EMAIL${normal}"
echo ""

if [ "${PYTHON_SMTP_SUCCESS:-false}" = "true" ]; then
    echo "${green}✅ Email sending is working via SMTP!${normal}"
    echo ""
    echo "Next steps:"
    echo "  • Check your inbox: $TEST_EMAIL"
    echo "  • Check spam folder if not received"
    echo "  • Configure REPORT_EMAIL in config.sh for automated reports"
    echo "  • Configure ALERT_EMAIL in config.sh for security alerts"
    echo ""
    echo "${green}✅ SMTP is configured and working!${normal}"
elif [ "${MAIL_SUCCESS:-false}" = "true" ] || [ "${SENDMAIL_SUCCESS:-false}" = "true" ]; then
    echo "${yellow}⚠️  Email may have been queued, but may not actually send${normal}"
    echo ""
    echo "⚠️  IMPORTANT: On macOS, mail/sendmail often don't actually send emails."
    echo "   They just queue them locally. For reliable email delivery:"
    echo ""
    echo "   ${bold}Recommended: Configure SMTP${normal}"
    echo "   1. For Gmail: Create an App Password"
    echo "      • Go to: https://myaccount.google.com/apppasswords"
    echo "      • Generate an app password for 'Mail'"
    echo "   2. Set environment variables:"
    echo "      export SMTP_USERNAME='your-email@gmail.com'"
    echo "      export SMTP_PASSWORD='your-app-password'"
    echo "   3. Add to ~/.zshrc for persistence:"
    echo "      echo 'export SMTP_USERNAME=\"your-email@gmail.com\"' >> ~/.zshrc"
    echo "      echo 'export SMTP_PASSWORD=\"your-app-password\"' >> ~/.zshrc"
    echo "   4. Reload: source ~/.zshrc"
    echo "   5. Run this test again"
else
    echo "${red}❌ Email sending is not configured${normal}"
    echo ""
    echo "To enable email sending:"
    echo ""
    echo "  ${bold}Option 1: Configure SMTP (Recommended)${normal}"
    echo "  1. For Gmail: Create an App Password"
    echo "     • Go to: https://myaccount.google.com/apppasswords"
    echo "     • Generate an app password"
    echo "  2. Set environment variables:"
    echo "     export SMTP_USERNAME='your-email@gmail.com'"
    echo "     export SMTP_PASSWORD='your-app-password'"
    echo "  3. Add to ~/.zshrc for persistence"
    echo ""
    echo "  ${bold}Option 2: Use system mail (may not work on macOS)${normal}"
    echo "  • Install mailutils: brew install mailutils"
    echo "  • Configure in System Settings > Internet Accounts"
fi
echo ""

