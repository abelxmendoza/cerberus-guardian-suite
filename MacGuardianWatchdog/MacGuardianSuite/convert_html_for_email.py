#!/usr/bin/env python3
"""Convert HTML report to email-compatible HTML with inline styles."""

import sys
import re
from pathlib import Path

def convert_to_email_html(html_file: str) -> str:
    """Convert HTML with <style> tags to inline styles for email compatibility."""
    
    html_content = Path(html_file).read_text()
    
    # Extract styles from <style> tag
    style_match = re.search(r'<style>(.*?)</style>', html_content, re.DOTALL)
    if not style_match:
        return html_content
    
    styles = style_match.group(1)
    
    # Parse CSS rules (simple parser)
    css_rules = {}
    for rule in re.finditer(r'\.?([\w-]+)\s*\{([^}]+)\}', styles):
        selector = rule.group(1).strip()
        properties = rule.group(2).strip()
        css_rules[selector] = properties
    
    # Also handle element selectors
    for rule in re.finditer(r'([a-z]+)\s*\{([^}]+)\}', styles):
        selector = rule.group(1).strip()
        properties = rule.group(2).strip()
        css_rules[selector] = properties
    
    # Apply inline styles to elements
    result = html_content
    
    # Remove the <style> tag
    result = re.sub(r'<style>.*?</style>', '', result, flags=re.DOTALL)
    
    # Apply styles to body
    if 'body' in css_rules:
        body_style = css_rules['body']
        result = re.sub(r'<body([^>]*)>', f'<body\\1 style="{body_style}">', result)
    
    # Apply styles to elements with classes
    for selector, properties in css_rules.items():
        if selector.startswith('.'):
            class_name = selector[1:]  # Remove the dot
            # Find elements with this class and add inline styles
            pattern = f'class=["\']([^"\']*\\b{class_name}\\b[^"\']*)["\']'
            def add_style(match):
                existing_class = match.group(1)
                # Check if style already exists
                tag_match = re.search(r'<([^>]+class=["\']' + re.escape(existing_class) + r'["\'][^>]*)>', result)
                if tag_match:
                    tag_content = tag_match.group(1)
                    if 'style=' in tag_content:
                        # Append to existing style
                        return tag_content.replace('style="', f'style="{properties}; ')
                    else:
                        # Add new style attribute
                        return tag_content + f' style="{properties}"'
                return match.group(0)
            result = re.sub(pattern, add_style, result)
    
    # For better email compatibility, wrap in a table-based layout
    # Many email clients work better with tables
    email_wrapper = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <!--[if mso]>
    <style type="text/css">
        body, table, td {{font-family: Arial, sans-serif !important;}}
    </style>
    <![endif]-->
</head>
<body style="margin: 0; padding: 0; background-color: #0D0D12; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif;">
    <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="background-color: #0D0D12;">
        <tr>
            <td align="center" style="padding: 20px;">
                <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="600" style="max-width: 600px; background-color: #1a1a24;">
                    <tr>
                        <td>
{result.split('<body>')[1].split('</body>')[0] if '<body>' in result else result}
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>"""
    
    return email_wrapper

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: convert_html_for_email.py <html_file>")
        sys.exit(1)
    
    html_file = sys.argv[1]
    email_html = convert_to_email_html(html_file)
    print(email_html)

