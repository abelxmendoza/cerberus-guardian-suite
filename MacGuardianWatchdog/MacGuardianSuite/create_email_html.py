#!/usr/bin/env python3
"""Create email-compatible HTML from the report HTML file."""

import sys
import re
from pathlib import Path

def create_email_html(html_file: str) -> str:
    """Create email-compatible HTML with inline styles."""
    
    html_content = Path(html_file).read_text()
    
    # Extract logo if present (but we'll use a smaller version or remove it)
    # Email clients often have issues with large base64 images
    
    # Extract body content
    body_match = re.search(r'<body[^>]*>(.*?)</body>', html_content, re.DOTALL)
    if not body_match:
        return html_content
    
    body_content = body_match.group(1)
    
    # Remove script tags
    body_content = re.sub(r'<script[^>]*>.*?</script>', '', body_content, flags=re.DOTALL | re.IGNORECASE)
    
    # Extract style content and convert to inline styles where possible
    style_match = re.search(r'<style[^>]*>(.*?)</style>', html_content, re.DOTALL)
    styles = style_match.group(1) if style_match else ""
    
    # Create email-compatible HTML wrapper
    email_html = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>MacGuardian Security Report</title>
</head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif; margin: 0; padding: 0; background-color: #0D0D12; color: #E0E0E0;">
    <div style="max-width: 800px; margin: 0 auto; background-color: #1a1a24; padding: 0;">
        <!-- Header -->
        <div style="background: linear-gradient(135deg, #0D0D12 0%, #1a1a24 100%); padding: 30px 20px; border-bottom: 3px solid #8A29F0;">
            <div style="color: #8A29F0; font-size: 28px; font-weight: bold; margin-bottom: 8px;">🛡️ MacGuardian Security Report</div>
            <div style="color: #FFFFFF; font-size: 22px; font-weight: bold; margin-bottom: 5px;">Security Assessment Report</div>
            <div style="color: #8A29F0; font-size: 14px; letter-spacing: 2px; margin-top: 12px; font-weight: 600;">OMEGA TECHNOLOGIES</div>
        </div>
        
        <!-- Content -->
        <div style="padding: 20px;">
            {body_content}
        </div>
        
        <!-- Footer -->
        <div style="margin-top: 40px; padding: 30px 20px; border-top: 2px solid #8A29F0; background-color: #0D0D12; text-align: center; color: #888; font-size: 12px;">
            <div style="color: #8A29F0; font-weight: bold; font-size: 14px; margin-top: 10px;">🛡️ MacGuardian Security Suite</div>
            <div style="color: #8A29F0; font-weight: bold; margin-top: 10px;">Powered by OMEGA TECHNOLOGIES</div>
            <p style="margin-top: 10px;">Security Intelligence Platform</p>
        </div>
    </div>
</body>
</html>"""
    
    return email_html

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: create_email_html.py <input_html_file>")
        sys.exit(1)
    
    input_file = sys.argv[1]
    email_html = create_email_html(input_file)
    print(email_html)
