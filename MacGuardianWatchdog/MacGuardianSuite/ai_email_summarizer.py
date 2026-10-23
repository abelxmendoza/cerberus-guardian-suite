#!/usr/bin/env python3
"""
AI-Powered Email Summarizer
Generates easy-to-understand summaries of security events using AI/ML
"""

import sys
import json
import os
from datetime import datetime, timedelta
from collections import defaultdict
import re

def analyze_security_events(events):
    """Analyze security events and generate insights"""
    if not events:
        return {
            "summary": "No security events to analyze.",
            "severity": "info",
            "recommendations": []
        }
    
    # Categorize events
    categories = defaultdict(list)
    severity_counts = {"critical": 0, "high": 0, "medium": 0, "low": 0, "info": 0}
    
    for event in events:
        category = event.get("category", "general")
        severity = event.get("severity", "info").lower()
        categories[category].append(event)
        severity_counts[severity] = severity_counts.get(severity, 0) + 1
    
    # Generate summary
    total_events = len(events)
    critical_count = severity_counts["critical"]
    high_count = severity_counts["high"]
    
    if critical_count > 0:
        severity = "critical"
        summary = f"🚨 CRITICAL: {critical_count} critical security issue(s) detected!"
    elif high_count > 0:
        severity = "high"
        summary = f"⚠️ HIGH PRIORITY: {high_count} high-priority security issue(s) found."
    elif total_events > 0:
        severity = "medium"
        summary = f"ℹ️ {total_events} security event(s) detected. Review recommended."
    else:
        severity = "info"
        summary = "✅ All security checks passed. Your system is secure."
    
    # Generate recommendations
    recommendations = []
    
    if "malware" in categories or "virus" in categories:
        recommendations.append("Run a full antivirus scan to remove any detected threats.")
    
    if "permissions" in categories:
        recommendations.append("Review and fix file permissions to prevent unauthorized access.")
    
    if "network" in categories:
        recommendations.append("Check network connections and firewall rules.")
    
    if "updates" in categories:
        recommendations.append("Install pending system updates to patch security vulnerabilities.")
    
    if critical_count > 0:
        recommendations.append("Take immediate action on critical issues. Consider running remediation.")
    
    if not recommendations:
        recommendations.append("Continue regular security monitoring.")
    
    return {
        "summary": summary,
        "severity": severity,
        "total_events": total_events,
        "by_category": {k: len(v) for k, v in categories.items()},
        "by_severity": severity_counts,
        "recommendations": recommendations,
        "top_issues": get_top_issues(events, 5)
    }

def get_top_issues(events, limit=5):
    """Get top priority issues"""
    # Sort by severity (critical > high > medium > low > info)
    severity_order = {"critical": 0, "high": 1, "medium": 2, "low": 3, "info": 4}
    
    sorted_events = sorted(
        events,
        key=lambda x: severity_order.get(x.get("severity", "info").lower(), 99)
    )
    
    return sorted_events[:limit]

def generate_trend_analysis(historical_data):
    """Analyze trends over time using simple ML"""
    if not historical_data or len(historical_data) < 2:
        return None
    
    # Simple trend detection
    recent = historical_data[-7:] if len(historical_data) >= 7 else historical_data
    older = historical_data[-14:-7] if len(historical_data) >= 14 else historical_data[:len(recent)]
    
    recent_avg = sum(d.get("issue_count", 0) for d in recent) / len(recent) if recent else 0
    older_avg = sum(d.get("issue_count", 0) for d in older) / len(older) if older else 0
    
    trend = "stable"
    if recent_avg > older_avg * 1.2:
        trend = "increasing"
    elif recent_avg < older_avg * 0.8:
        trend = "decreasing"
    
    return {
        "trend": trend,
        "recent_avg": recent_avg,
        "change_percent": ((recent_avg - older_avg) / older_avg * 100) if older_avg > 0 else 0
    }

def generate_natural_language_report(analysis, trend=None):
    """Generate human-readable report"""
    report = []
    
    # Header
    report.append("📊 SECURITY SUMMARY")
    report.append("=" * 50)
    report.append("")
    
    # Main summary
    report.append(analysis["summary"])
    report.append("")
    
    # Statistics
    report.append("📈 STATISTICS:")
    report.append(f"  • Total Events: {analysis['total_events']}")
    report.append(f"  • Critical: {analysis['by_severity'].get('critical', 0)}")
    report.append(f"  • High: {analysis['by_severity'].get('high', 0)}")
    report.append(f"  • Medium: {analysis['by_severity'].get('medium', 0)}")
    report.append("")
    
    # Top issues
    if analysis.get("top_issues"):
        report.append("🔍 TOP PRIORITY ISSUES:")
        for i, issue in enumerate(analysis["top_issues"], 1):
            title = issue.get("title", "Unknown issue")
            severity = issue.get("severity", "info").upper()
            report.append(f"  {i}. [{severity}] {title}")
        report.append("")
    
    # Trend analysis
    if trend:
        if trend["trend"] == "increasing":
            report.append(f"📈 TREND: Issues are increasing ({trend['change_percent']:.1f}% increase)")
            report.append("   This suggests you may need to take action.")
        elif trend["trend"] == "decreasing":
            report.append(f"📉 TREND: Issues are decreasing ({abs(trend['change_percent']):.1f}% decrease)")
            report.append("   Great! Your security posture is improving.")
        else:
            report.append("📊 TREND: Issues are stable")
        report.append("")
    
    # Recommendations
    if analysis.get("recommendations"):
        report.append("💡 RECOMMENDATIONS:")
        for i, rec in enumerate(analysis["recommendations"], 1):
            report.append(f"  {i}. {rec}")
        report.append("")
    
    return "\n".join(report)

def generate_html_email(analysis, trend=None, events=None):
    """Generate HTML email template"""
    severity_colors = {
        "critical": "#dc3545",
        "high": "#fd7e14",
        "medium": "#ffc107",
        "low": "#17a2b8",
        "info": "#28a745"
    }
    
    color = severity_colors.get(analysis["severity"], "#6c757d")
    
    html = f"""
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; line-height: 1.6; color: #333; }}
        .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
        .header {{ background: {color}; color: white; padding: 20px; border-radius: 8px 8px 0 0; }}
        .content {{ background: #f8f9fa; padding: 20px; border-radius: 0 0 8px 8px; }}
        .summary {{ font-size: 18px; font-weight: bold; margin: 20px 0; }}
        .stat-box {{ background: white; padding: 15px; margin: 10px 0; border-radius: 5px; border-left: 4px solid {color}; }}
        .issue-item {{ background: white; padding: 10px; margin: 5px 0; border-radius: 5px; }}
        .badge {{ display: inline-block; padding: 3px 8px; border-radius: 3px; font-size: 12px; font-weight: bold; }}
        .badge-critical {{ background: #dc3545; color: white; }}
        .badge-high {{ background: #fd7e14; color: white; }}
        .badge-medium {{ background: #ffc107; color: #333; }}
        .recommendation {{ background: #e7f3ff; padding: 10px; margin: 5px 0; border-radius: 5px; border-left: 3px solid #007aff; }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🛡️ MacGuardian Security Report</h1>
            <p>{datetime.now().strftime('%B %d, %Y at %I:%M %p')}</p>
        </div>
        <div class="content">
            <div class="summary">{analysis['summary']}</div>
            
            <div class="stat-box">
                <h3>📊 Statistics</h3>
                <p><strong>Total Events:</strong> {analysis['total_events']}</p>
                <p><strong>Critical:</strong> {analysis['by_severity'].get('critical', 0)} | 
                   <strong>High:</strong> {analysis['by_severity'].get('high', 0)} | 
                   <strong>Medium:</strong> {analysis['by_severity'].get('medium', 0)}</p>
            </div>
"""
    
    if analysis.get("top_issues"):
        html += """
            <div class="stat-box">
                <h3>🔍 Top Priority Issues</h3>
"""
        for issue in analysis["top_issues"]:
            severity = issue.get("severity", "info").lower()
            title = issue.get("title", "Unknown issue")
            html += f"""
                <div class="issue-item">
                    <span class="badge badge-{severity}">{severity.upper()}</span>
                    <strong>{title}</strong>
                </div>
"""
        html += """
            </div>
"""
    
    if trend:
        trend_icon = "📈" if trend["trend"] == "increasing" else "📉" if trend["trend"] == "decreasing" else "📊"
        html += f"""
            <div class="stat-box">
                <h3>{trend_icon} Trend Analysis</h3>
                <p>Security issues are <strong>{trend['trend']}</strong></p>
"""
        if trend["trend"] != "stable":
            html += f"<p>Change: {trend['change_percent']:.1f}%</p>"
        html += """
            </div>
"""
    
    if analysis.get("recommendations"):
        html += """
            <div class="stat-box">
                <h3>💡 Recommendations</h3>
"""
        for rec in analysis["recommendations"]:
            html += f'<div class="recommendation">{rec}</div>'
        html += """
            </div>
"""
    
    html += """
            <p style="margin-top: 20px; font-size: 12px; color: #666;">
                This report was generated by MacGuardian Suite with AI-powered analysis.
            </p>
        </div>
    </div>
</body>
</html>
"""
    
    return html

def main():
    """Main function"""
    if len(sys.argv) < 2:
        print("Usage: ai_email_summarizer.py <events_json_file>")
        sys.exit(1)
    
    events_file = sys.argv[1]
    
    # Load events
    events = []
    if os.path.exists(events_file):
        with open(events_file, 'r') as f:
            events = json.load(f)
    
    # Analyze
    analysis = analyze_security_events(events)
    
    # Generate reports
    text_report = generate_natural_language_report(analysis)
    html_report = generate_html_email(analysis)
    
    # Output
    print("TEXT_REPORT_START")
    print(text_report)
    print("TEXT_REPORT_END")
    
    print("HTML_REPORT_START")
    print(html_report)
    print("HTML_REPORT_END")
    
    # Also output JSON for programmatic use
    print("JSON_ANALYSIS_START")
    print(json.dumps(analysis, indent=2))
    print("JSON_ANALYSIS_END")

if __name__ == "__main__":
    main()

