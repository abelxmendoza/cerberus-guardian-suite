#!/usr/bin/env python3
"""Omega Tech Black-Ops Email Dispatcher for the MacGuardian Suite."""

import argparse
import os
import smtplib
import sys
from email import encoders
from email.mime.base import MIMEBase
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from pathlib import Path
from typing import Dict, Optional
import html

THEME_ID = "omega_tech_black_ops"
THEME_ROOT = Path.home() / ".macguardian" / "themes" / THEME_ID
THEME_PROFILE_PATH = THEME_ROOT / "profile.conf"
THEME_TEMPLATE_PATH = THEME_ROOT / "alert_template.html"


def load_theme_profile() -> Dict[str, str]:
    """Load key/value pairs from the theme profile file."""
    profile: Dict[str, str] = {}
    if THEME_PROFILE_PATH.exists():
        for raw_line in THEME_PROFILE_PATH.read_text().splitlines():
            line = raw_line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            profile[key.strip()] = value.strip().strip('"')
    return profile


THEME_PROFILE = load_theme_profile()
THEME_SUBJECT_PREFIX = THEME_PROFILE.get("THEME_SUBJECT_PREFIX", "[Ω-OPS]")
THEME_HEADLINE = THEME_PROFILE.get("THEME_HEADLINE", "OMEGA TECH // BLACK-OPS ALERT")
THEME_STATUS_LINE = THEME_PROFILE.get("THEME_STATUS_LINE", "Automation Wing // Active Oversight")
THEME_TAGLINE = THEME_PROFILE.get("THEME_TAGLINE", "Omega Technologies // Watchdog Division")


def render_theme_html(message: str, headline: Optional[str] = None, status_line: Optional[str] = None,
                      tagline: Optional[str] = None) -> str:
    """Wrap message content in the Omega Tech Black-Ops HTML template."""
    try:
        template = THEME_TEMPLATE_PATH.read_text()
    except FileNotFoundError:
        template = """<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"UTF-8\"><title>{{headline}}</title>
<style>body{background-color:#0D0D0D;color:#E5E5E5;font-family:'Courier New',Menlo,monospace;margin:0;padding:32px}a{color:#FFE600}</style>
</head><body><h1 style=\"color:#8C00FF;text-transform:uppercase;letter-spacing:0.2em;font-size:20px;\">{{headline}}</h1>
<p style=\"color:#FFE600;letter-spacing:0.18em;text-transform:uppercase;font-size:12px;\">{{status_line}}</p>
<div style=\"line-height:1.6;font-size:14px;\">{{body}}</div>
<p style=\"margin-top:32px;font-size:12px;color:#8C00FF;letter-spacing:0.22em;\">{{tagline}}</p>
<p style=\"font-size:11px;color:#666666;letter-spacing:0.16em;text-transform:uppercase;\">Omega Technologies • Black-Ops Watchdog</p>
</body></html>"""

    safe_body = "<br>".join(html.escape(line) for line in message.splitlines()) if message else ""

    replacements = {
        "{{headline}}": html.escape((headline or THEME_HEADLINE).strip()),
        "{{status_line}}": html.escape((status_line or THEME_STATUS_LINE).strip()),
        "{{body}}": safe_body,
        "{{tagline}}": html.escape((tagline or THEME_TAGLINE).strip()),
    }

    for token, value in replacements.items():
        template = template.replace(token, value)
    return template


def send_email(to_email: str, subject: str, body: str, html_body: Optional[str] = None,
               attachment_path: Optional[str] = None, smtp_config: Optional[Dict[str, str]] = None) -> bool:
    """Send email using SMTP with Omega Tech styling."""

    default_config = {
        "smtp_server": "smtp.gmail.com",
        "smtp_port": 587,
        "use_tls": True,
        "username": None,
        "password": None,
    }

    if smtp_config:
        default_config.update({k: v for k, v in smtp_config.items() if v is not None})

    config = default_config

    if not config["username"]:
        config["username"] = os.environ.get("SMTP_USERNAME") or os.environ.get("EMAIL_USERNAME")
    if not config["password"]:
        config["password"] = (
            os.environ.get("SMTP_PASSWORD")
            or os.environ.get("EMAIL_PASSWORD")
            or os.environ.get("GMAIL_APP_PASSWORD")
        )

    if not config["username"] or not config["password"]:
        print("Ω⚠️  SMTP credentials not configured. Using system mail as fallback if available.")
        print("   Export SMTP_USERNAME and SMTP_PASSWORD to dispatch over TLS.")
        return False

    prefix = THEME_SUBJECT_PREFIX.strip()
    clean_subject = subject.strip()
    if prefix and not clean_subject.startswith(prefix):
        clean_subject = f"{prefix} {clean_subject}"

    base_message = body or ""
    base_message = base_message.strip("\n")
    tagline = THEME_TAGLINE.strip()
    if tagline and tagline not in base_message:
        text_body = f"{base_message}\n\n— {tagline}" if base_message else f"— {tagline}"
    else:
        text_body = base_message

    themed_html = html_body
    if themed_html is None:
        themed_html = render_theme_html(base_message, headline=THEME_HEADLINE,
                                        status_line=THEME_STATUS_LINE, tagline=tagline)

    try:
        if themed_html:
            msg = MIMEMultipart('alternative')
            msg.attach(MIMEText(text_body or base_message, 'plain'))
            msg.attach(MIMEText(themed_html, 'html'))
        else:
            msg = MIMEText(text_body or base_message)

        msg['Subject'] = clean_subject
        msg['From'] = config['username']
        msg['To'] = to_email

        if attachment_path and os.path.exists(attachment_path):
            with open(attachment_path, 'rb') as handle:
                part = MIMEBase('application', 'octet-stream')
                part.set_payload(handle.read())
                encoders.encode_base64(part)
                part.add_header('Content-Disposition',
                                 f'attachment; filename={os.path.basename(attachment_path)}')
                if isinstance(msg, MIMEMultipart):
                    msg.attach(part)

        if config['use_tls']:
            server = smtplib.SMTP(config['smtp_server'], config['smtp_port'])
            server.starttls()
        else:
            server = smtplib.SMTP_SSL(config['smtp_server'], config['smtp_port'])

        server.login(config['username'], config['password'])
        server.send_message(msg)
        server.quit()

        print(f"Ω✅ Transmission delivered to {to_email}")
        return True

    except smtplib.SMTPAuthenticationError:
        print("Ω❌ Authentication failed. Validate your SMTP username/password (App Password for Gmail).")
        return False
    except smtplib.SMTPException as exc:
        print(f"Ω❌ SMTP error: {exc}")
        return False
    except Exception as exc:  # pylint: disable=broad-except
        print(f"Ω❌ Error sending email: {exc}")
        return False


def main() -> None:
    parser = argparse.ArgumentParser(description='Send Omega Tech themed email via SMTP')
    parser.add_argument('to_email', help='Recipient email address')
    parser.add_argument('subject', help='Email subject')
    parser.add_argument('body', help='Email body')
    parser.add_argument('--html', help='Optional raw HTML body (will override theme wrapper)')
    parser.add_argument('--html-file', help='Path to HTML file to use as body')
    parser.add_argument('--attachment', help='Path to attachment file')
    parser.add_argument('--smtp-server', default='smtp.gmail.com', help='SMTP server')
    parser.add_argument('--smtp-port', type=int, default=587, help='SMTP port')
    parser.add_argument('--username', help='SMTP username')
    parser.add_argument('--password', help='SMTP password')

    args = parser.parse_args()

    smtp_config = {
        'smtp_server': args.smtp_server,
        'smtp_port': args.smtp_port,
        'username': args.username,
        'password': args.password,
    }

    # Read HTML from file if provided
    html_body = args.html
    if args.html_file and Path(args.html_file).exists():
        html_body = Path(args.html_file).read_text()
    
    success = send_email(
        args.to_email,
        args.subject,
        args.body,
        html_body=html_body,
        attachment_path=args.attachment,
        smtp_config=smtp_config,
    )

    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
