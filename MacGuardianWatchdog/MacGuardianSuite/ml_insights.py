#!/usr/bin/env python3
"""
ML-Powered Security Insights
Provides predictive analysis, anomaly detection, and intelligent recommendations
"""

import sys
import json
import os
from datetime import datetime, timedelta
from collections import defaultdict
import statistics

def calculate_risk_score(events, historical_data=None):
    """Calculate overall risk score (0-100)"""
    if not events:
        return 0
    
    severity_weights = {
        "critical": 10,
        "high": 5,
        "medium": 2,
        "low": 1,
        "info": 0
    }
    
    total_score = 0
    for event in events:
        severity = event.get("severity", "info").lower()
        total_score += severity_weights.get(severity, 0)
    
    # Normalize to 0-100
    max_possible = len(events) * 10
    risk_score = min(100, (total_score / max_possible * 100) if max_possible > 0 else 0)
    
    return round(risk_score, 1)

def detect_anomalies(current_events, historical_data=None):
    """Detect anomalies using statistical analysis"""
    if not historical_data or len(historical_data) < 3:
        return []
    
    # Calculate baseline statistics
    historical_counts = [d.get("issue_count", 0) for d in historical_data]
    if len(historical_counts) < 3:
        return []
    
    mean_count = statistics.mean(historical_counts)
    std_dev = statistics.stdev(historical_counts) if len(historical_counts) > 1 else 0
    
    current_count = len(current_events)
    
    anomalies = []
    
    # Detect spike in issues
    if std_dev > 0 and current_count > mean_count + (2 * std_dev):
        anomalies.append({
            "type": "issue_spike",
            "severity": "high",
            "description": f"Unusual spike in security issues detected ({current_count} vs average {mean_count:.1f})",
            "recommendation": "Investigate recent system changes or potential security breach"
        })
    
    # Detect new attack patterns
    current_categories = set(e.get("category", "unknown") for e in current_events)
    historical_categories = set()
    for h in historical_data:
        historical_categories.update(h.get("categories", []))
    
    new_categories = current_categories - historical_categories
    if new_categories:
        anomalies.append({
            "type": "new_threat_category",
            "severity": "medium",
            "description": f"New threat category detected: {', '.join(new_categories)}",
            "recommendation": "Review and understand new threat vectors"
        })
    
    return anomalies

def predict_future_risks(historical_data):
    """Simple predictive analysis"""
    if not historical_data or len(historical_data) < 7:
        return None
    
    # Simple linear trend
    recent = historical_data[-7:]
    issue_counts = [d.get("issue_count", 0) for d in recent]
    
    if len(issue_counts) < 2:
        return None
    
    # Calculate trend
    trend = (issue_counts[-1] - issue_counts[0]) / len(issue_counts)
    
    prediction = {
        "trend": "increasing" if trend > 0.5 else "decreasing" if trend < -0.5 else "stable",
        "predicted_next_week": max(0, round(issue_counts[-1] + trend * 7)),
        "confidence": "medium"
    }
    
    return prediction

def generate_ai_recommendations(events, risk_score, anomalies=None, prediction=None):
    """Generate intelligent recommendations using AI/ML insights"""
    recommendations = []
    
    # Risk-based recommendations
    if risk_score > 70:
        recommendations.append({
            "priority": "critical",
            "action": "Immediate action required",
            "description": "Your system has a high risk score. Run full remediation immediately.",
            "command": "./MacGuardianSuite/mac_remediation.sh --execute"
        })
    elif risk_score > 40:
        recommendations.append({
            "priority": "high",
            "action": "Review and fix issues",
            "description": "Moderate risk detected. Review security issues and apply fixes.",
            "command": "./MacGuardianSuite/mac_remediation.sh"
        })
    
    # Anomaly-based recommendations
    if anomalies:
        for anomaly in anomalies:
            if anomaly.get("severity") in ["high", "critical"]:
                recommendations.append({
                    "priority": anomaly.get("severity"),
                    "action": "Investigate anomaly",
                    "description": anomaly.get("description"),
                    "recommendation": anomaly.get("recommendation")
                })
    
    # Prediction-based recommendations
    if prediction and prediction.get("trend") == "increasing":
        recommendations.append({
            "priority": "medium",
            "action": "Proactive security hardening",
            "description": f"Trend analysis predicts {prediction['predicted_next_week']} issues next week. Take preventive action.",
            "command": "./MacGuardianSuite/hardening_assessment.sh"
        })
    
    # Category-specific recommendations
    categories = defaultdict(int)
    for event in events:
        categories[event.get("category", "unknown")] += 1
    
    if categories.get("malware", 0) > 0:
        recommendations.append({
            "priority": "high",
            "action": "Full antivirus scan",
            "description": "Malware detected. Run comprehensive antivirus scan.",
            "command": "./MacGuardianSuite/mac_guardian.sh"
        })
    
    if categories.get("network", 0) > 2:
        recommendations.append({
            "priority": "medium",
            "action": "Network security review",
            "description": "Multiple network issues detected. Review firewall and network connections.",
            "command": "./MacGuardianSuite/mac_blueteam.sh"
        })
    
    if not recommendations:
        recommendations.append({
            "priority": "low",
            "action": "Continue monitoring",
            "description": "System appears secure. Continue regular monitoring.",
            "command": None
        })
    
    return recommendations

def generate_ml_summary(events, historical_data=None):
    """Generate ML-powered summary"""
    risk_score = calculate_risk_score(events, historical_data)
    anomalies = detect_anomalies(events, historical_data) if historical_data else []
    prediction = predict_future_risks(historical_data) if historical_data else None
    recommendations = generate_ai_recommendations(events, risk_score, anomalies, prediction)
    
    return {
        "risk_score": risk_score,
        "anomalies": anomalies,
        "prediction": prediction,
        "recommendations": recommendations,
        "summary": generate_summary_text(risk_score, len(events), anomalies, prediction)
    }

def generate_summary_text(risk_score, event_count, anomalies, prediction):
    """Generate human-readable summary"""
    if risk_score > 70:
        return f"🚨 CRITICAL RISK: {risk_score}/100. {event_count} security event(s) detected. Immediate action required."
    elif risk_score > 40:
        return f"⚠️ MODERATE RISK: {risk_score}/100. {event_count} security event(s) detected. Review recommended."
    elif event_count > 0:
        return f"ℹ️ LOW RISK: {risk_score}/100. {event_count} security event(s) detected. Monitor closely."
    else:
        return f"✅ SECURE: {risk_score}/100. No security issues detected."

def main():
    """Main function"""
    if len(sys.argv) < 2:
        print("Usage: ml_insights.py <events_json_file> [historical_json_file]")
        sys.exit(1)
    
    events_file = sys.argv[1]
    historical_file = sys.argv[2] if len(sys.argv) > 2 else None
    
    # Load events
    events = []
    if os.path.exists(events_file):
        with open(events_file, 'r') as f:
            events = json.load(f)
    
    # Load historical data
    historical_data = None
    if historical_file and os.path.exists(historical_file):
        with open(historical_file, 'r') as f:
            historical_data = json.load(f)
    
    # Generate ML insights
    insights = generate_ml_summary(events, historical_data)
    
    # Output JSON
    print("ML_INSIGHTS_START")
    print(json.dumps(insights, indent=2))
    print("ML_INSIGHTS_END")

if __name__ == "__main__":
    main()

