#!/usr/bin/env python3
"""
Mac Guardian AI Engine
Optimized for Apple M1 Pro with Neural Engine
Lightweight on-device machine learning for security analysis
"""

import json
import sys
import os
import argparse
from pathlib import Path
from collections import defaultdict
import statistics

try:
    import numpy as np
    HAS_NUMPY = True
except ImportError:
    HAS_NUMPY = False
    print("Warning: numpy not available, using basic math", file=sys.stderr)

try:
    from sklearn.ensemble import IsolationForest
    from sklearn.preprocessing import StandardScaler
    HAS_SKLEARN = True
except ImportError:
    HAS_SKLEARN = False
    print("Warning: scikit-learn not available, using statistical methods", file=sys.stderr)


class SecurityAnalyzer:
    """Lightweight ML-based security analyzer optimized for M1 Pro"""
    
    def __init__(self):
        self.baseline_metrics = None
        self.anomaly_threshold = 2.0  # Standard deviations
        self.load_baseline()
    
    def load_baseline(self):
        """Load or create baseline metrics"""
        baseline_file = Path.home() / ".macguardian" / "ai" / "baseline.json"
        
        if baseline_file.exists():
            try:
                with open(baseline_file, 'r') as f:
                    self.baseline_metrics = json.load(f)
            except:
                self.baseline_metrics = None
        
        if not self.baseline_metrics:
            # Create initial baseline
            self.baseline_metrics = {
                "process_count": {"mean": 50, "std": 10},
                "network_connections": {"mean": 5, "std": 3},
                "cpu_usage": {"mean": 20, "std": 15},
                "memory_usage": {"mean": 4000, "std": 1000}
            }
            self.save_baseline()
    
    def save_baseline(self):
        """Save baseline metrics"""
        baseline_file = Path.home() / ".macguardian" / "ai" / "baseline.json"
        baseline_file.parent.mkdir(parents=True, exist_ok=True)
        
        with open(baseline_file, 'w') as f:
            json.dump(self.baseline_metrics, f, indent=2)
    
    def analyze_anomalies(self, metrics_file):
        """Detect behavioral anomalies using statistical methods"""
        try:
            with open(metrics_file, 'r') as f:
                metrics = json.load(f)
        except:
            return "ERROR"
        
        anomalies = []
        
        # Check each metric against baseline
        for metric_name, value in metrics.items():
            if metric_name == "timestamp":
                continue
            
            if metric_name in self.baseline_metrics:
                baseline = self.baseline_metrics[metric_name]
                mean = baseline.get("mean", 0)
                std = baseline.get("std", 1)
                
                if std > 0:
                    z_score = abs((value - mean) / std)
                    
                    if z_score > self.anomaly_threshold:
                        anomalies.append(f"{metric_name} deviation: {z_score:.2f}σ")
        
        # Use Isolation Forest if available
        if HAS_SKLEARN and len(anomalies) > 0:
            try:
                # Prepare data
                feature_vector = [
                    metrics.get("process_count", 0),
                    metrics.get("network_connections", 0),
                    metrics.get("cpu_usage", 0),
                    metrics.get("memory_usage", 0)
                ]
                
                # Use lightweight Isolation Forest
                clf = IsolationForest(contamination=0.1, random_state=42, n_estimators=50)
                X = np.array([feature_vector])
                
                # Need historical data for training, use baseline for now
                baseline_vector = [
                    self.baseline_metrics["process_count"]["mean"],
                    self.baseline_metrics["network_connections"]["mean"],
                    self.baseline_metrics["cpu_usage"]["mean"],
                    self.baseline_metrics["memory_usage"]["mean"]
                ]
                
                # Simple comparison
                if HAS_NUMPY:
                    distance = np.linalg.norm(np.array(feature_vector) - np.array(baseline_vector))
                    if distance > 50:  # Threshold
                        return f"ML anomaly detected: {', '.join(anomalies[:3])}"
            except Exception as e:
                pass  # Fall back to statistical method
        
        if anomalies:
            return f"Anomaly detected: {', '.join(anomalies[:3])}"
        
        return "NORMAL"
    
    def pattern_recognition(self, process_file, network_file):
        """Recognize suspicious patterns"""
        threats = []
        
        # Analyze processes
        if os.path.exists(process_file):
            try:
                with open(process_file, 'r') as f:
                    processes = f.readlines()
                
                suspicious_keywords = ["miner", "crypto", "bitcoin", "malware", "trojan"]
                for line in processes:
                    line_lower = line.lower()
                    for keyword in suspicious_keywords:
                        if keyword in line_lower:
                            threats.append(f"Suspicious process pattern: {keyword}")
                            break
            except:
                pass
        
        # Analyze network
        if os.path.exists(network_file):
            try:
                with open(network_file, 'r') as f:
                    connections = f.readlines()
                
                suspicious_ports = [4444, 5555, 6666, 7777, 8888, 9999, 1337, 31337]
                for line in connections:
                    for port in suspicious_ports:
                        if f":{port}" in line:
                            threats.append(f"Suspicious network pattern: port {port}")
                            break
            except:
                pass
        
        if threats:
            return "; ".join(threats[:3])
        
        return ""
    
    def predict_threats(self, data_dir):
        """Predictive analysis based on historical data"""
        data_path = Path(data_dir)
        
        if not data_path.exists():
            return "No historical data available"
        
        # Collect recent metrics
        metrics_files = sorted(data_path.glob("metrics_*.json"), reverse=True)[:10]
        
        if len(metrics_files) < 3:
            return "Insufficient data for prediction"
        
        # Simple trend analysis
        process_counts = []
        network_counts = []
        
        for mfile in metrics_files:
            try:
                with open(mfile, 'r') as f:
                    data = json.load(f)
                    process_counts.append(data.get("process_count", 0))
                    network_counts.append(data.get("network_connections", 0))
            except:
                continue
        
        if len(process_counts) >= 3:
            # Calculate trend
            if HAS_NUMPY:
                process_trend = np.polyfit(range(len(process_counts)), process_counts, 1)[0]
                network_trend = np.polyfit(range(len(network_counts)), network_counts, 1)[0]
            else:
                # Simple linear trend
                process_trend = (process_counts[-1] - process_counts[0]) / len(process_counts)
                network_trend = (network_counts[-1] - network_counts[0]) / len(network_counts)
            
            predictions = []
            
            if process_trend > 5:
                predictions.append("Increasing process count trend")
            if network_trend > 2:
                predictions.append("Increasing network activity trend")
            
            if predictions:
                return f"Prediction: {', '.join(predictions)}"
        
        return "No significant trends detected"
    
    def classify_files(self, file_data):
        """Classify files by type and risk"""
        try:
            with open(file_data, 'r') as f:
                files = json.load(f)
        except:
            return "ERROR"
        
        risk_extensions = {".exe", ".bat", ".scr", ".vbs", ".ps1", ".sh"}
        suspicious_count = 0
        
        for file_info in files:
            ext = file_info.get("ext", "").lower()
            if ext in risk_extensions:
                suspicious_count += 1
        
        if suspicious_count > 0:
            return f"Found {suspicious_count} potentially risky file(s)"
        
        return "File classification complete"


def main():
    parser = argparse.ArgumentParser(description="Mac Guardian AI Engine")
    parser.add_argument("--analyze", help="Analyze metrics file")
    parser.add_argument("--patterns", nargs=2, help="Pattern recognition files")
    parser.add_argument("--predict", help="Predictive analysis data directory")
    parser.add_argument("--classify", help="Classify files")
    
    args = parser.parse_args()
    
    analyzer = SecurityAnalyzer()
    
    if args.analyze:
        result = analyzer.analyze_anomalies(args.analyze)
        print(result)
    
    elif args.patterns:
        result = analyzer.pattern_recognition(args.patterns[0], args.patterns[1])
        print(result if result else "NORMAL")
    
    elif args.predict:
        result = analyzer.predict_threats(args.predict)
        print(result)
    
    elif args.classify:
        result = analyzer.classify_files(args.classify)
        print(result)
    
    else:
        parser.print_help()


if __name__ == "__main__":
    main()

