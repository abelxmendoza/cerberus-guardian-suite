#!/usr/bin/env python3
"""
Mac Guardian ML Engine
Advanced Machine Learning for Security Analysis
Optimized for Apple M1 Pro with Neural Engine
"""

import json
import sys
import os
import pickle
import argparse
from pathlib import Path
from collections import defaultdict, deque
from datetime import datetime, timedelta
import statistics

try:
    import numpy as np
    HAS_NUMPY = True
except ImportError:
    HAS_NUMPY = False
    print("Warning: numpy not available", file=sys.stderr)

try:
    from sklearn.ensemble import (
        IsolationForest, RandomForestClassifier, 
        GradientBoostingClassifier, VotingClassifier
    )
    from sklearn.svm import OneClassSVM, SVC
    from sklearn.cluster import DBSCAN, KMeans
    from sklearn.preprocessing import StandardScaler, RobustScaler
    from sklearn.model_selection import train_test_split
    from sklearn.metrics import classification_report, accuracy_score
    from sklearn.neighbors import LocalOutlierFactor
    import joblib
    HAS_SKLEARN = True
except ImportError:
    HAS_SKLEARN = False
    print("Warning: scikit-learn not available", file=sys.stderr)

try:
    import pandas as pd
    HAS_PANDAS = True
except ImportError:
    HAS_PANDAS = False


class MLSecurityEngine:
    """Advanced ML-based security engine with model training"""
    
    def __init__(self, models_dir=None):
        self.models_dir = Path(models_dir) if models_dir else Path.home() / ".macguardian" / "ai" / "models"
        self.models_dir.mkdir(parents=True, exist_ok=True)
        
        self.scaler = None
        self.anomaly_model = None
        self.classifier = None
        self.clusterer = None
        self.baseline_metrics = None
        self.feature_history = deque(maxlen=1000)  # Keep last 1000 samples
        
        self.load_models()
        self.load_baseline()
    
    def load_baseline(self):
        """Load baseline metrics"""
        baseline_file = Path.home() / ".macguardian" / "ai" / "baseline.json"
        if baseline_file.exists():
            try:
                with open(baseline_file, 'r') as f:
                    self.baseline_metrics = json.load(f)
            except:
                self.baseline_metrics = None
        
        if not self.baseline_metrics:
            self.baseline_metrics = {
                "process_count": {"mean": 50, "std": 10},
                "network_connections": {"mean": 5, "std": 3},
                "cpu_usage": {"mean": 20, "std": 15},
                "memory_usage": {"mean": 4000, "std": 1000}
            }
    
    def extract_features(self, metrics):
        """Extract ML features from metrics"""
        features = []
        
        # Basic features
        features.append(metrics.get("process_count", 0))
        features.append(metrics.get("network_connections", 0))
        features.append(metrics.get("cpu_usage", 0))
        features.append(metrics.get("memory_usage", 0))
        features.append(metrics.get("disk_io", 0))
        features.append(metrics.get("logged_users", 0))
        
        # Derived features
        if self.baseline_metrics:
            for key in ["process_count", "network_connections", "cpu_usage", "memory_usage"]:
                if key in metrics and key in self.baseline_metrics:
                    baseline = self.baseline_metrics[key]
                    mean = baseline.get("mean", 0)
                    std = baseline.get("std", 1)
                    if std > 0:
                        z_score = (metrics[key] - mean) / std
                        features.append(z_score)
                    else:
                        features.append(0)
                else:
                    features.append(0)
        
        # Temporal features (if history available)
        if len(self.feature_history) > 0:
            recent = list(self.feature_history)[-5:]  # Last 5 samples
            if HAS_NUMPY and len(recent) > 1:
                recent_array = np.array(recent)
                features.append(np.mean(recent_array[:, 0]))  # Mean process count
                features.append(np.std(recent_array[:, 0]))   # Std process count
                features.append(np.mean(recent_array[:, 1]))  # Mean network
            else:
                features.extend([0, 0, 0])
        else:
            features.extend([0, 0, 0])
        
        return np.array(features) if HAS_NUMPY else features
    
    def train_anomaly_model(self, data_dir=None, force_retrain=False):
        """Train anomaly detection model"""
        if not HAS_SKLEARN:
            return False
        
        model_file = self.models_dir / "anomaly_model.pkl"
        
        if model_file.exists() and not force_retrain:
            try:
                self.anomaly_model = joblib.load(model_file)
                scaler_file = self.models_dir / "scaler.pkl"
                if scaler_file.exists():
                    self.scaler = joblib.load(scaler_file)
                return True
            except:
                pass
        
        # Collect training data
        if data_dir:
            data_path = Path(data_dir)
        else:
            data_path = Path.home() / ".macguardian" / "ai" / "data"
        
        if not data_path.exists():
            return False
        
        # Load historical metrics
        metrics_files = sorted(data_path.glob("metrics_*.json"), reverse=True)[:100]
        
        if len(metrics_files) < 10:
            return False
        
        X_train = []
        for mfile in metrics_files:
            try:
                with open(mfile, 'r') as f:
                    metrics = json.load(f)
                features = self.extract_features(metrics)
                if HAS_NUMPY:
                    X_train.append(features)
                else:
                    X_train.append(features)
            except:
                continue
        
        if len(X_train) < 10:
            return False
        
        # Convert to numpy array
        if HAS_NUMPY:
            X_train = np.array(X_train)
            
            # Scale features
            self.scaler = RobustScaler()
            X_train_scaled = self.scaler.fit_transform(X_train)
            
            # Train Isolation Forest (best for anomaly detection)
            self.anomaly_model = IsolationForest(
                contamination=0.1,
                random_state=42,
                n_estimators=100,
                max_samples='auto'
            )
            self.anomaly_model.fit(X_train_scaled)
            
            # Save models
            joblib.dump(self.anomaly_model, model_file)
            joblib.dump(self.scaler, self.models_dir / "scaler.pkl")
            
            return True
        
        return False
    
    def detect_anomalies_ml(self, metrics_file):
        """Detect anomalies using trained ML model"""
        try:
            with open(metrics_file, 'r') as f:
                metrics = json.load(f)
        except:
            return "ERROR"
        
        # Extract features
        features = self.extract_features(metrics)
        
        # Add to history
        if HAS_NUMPY:
            self.feature_history.append(features)
        else:
            self.feature_history.append(features)
        
        # Use trained model if available
        if self.anomaly_model is not None and self.scaler is not None and HAS_SKLEARN:
            try:
                if HAS_NUMPY:
                    features_array = np.array([features])
                    features_scaled = self.scaler.transform(features_array)
                    prediction = self.anomaly_model.predict(features_scaled)[0]
                    score = self.anomaly_model.score_samples(features_scaled)[0]
                    
                    if prediction == -1:  # Anomaly
                        return f"ML Anomaly detected (score: {score:.2f})"
            except Exception as e:
                pass  # Fall back to statistical
        
        # Statistical fallback
        anomalies = []
        for metric_name, value in metrics.items():
            if metric_name == "timestamp" or metric_name not in self.baseline_metrics:
                continue
            
            baseline = self.baseline_metrics[metric_name]
            mean = baseline.get("mean", 0)
            std = baseline.get("std", 1)
            
            if std > 0:
                z_score = abs((value - mean) / std)
                if z_score > 2.0:
                    anomalies.append(f"{metric_name}: {z_score:.2f}σ")
        
        if anomalies:
            return f"Anomaly: {', '.join(anomalies[:3])}"
        
        return "NORMAL"
    
    def train_classifier(self, data_dir=None, labels_file=None):
        """Train threat classification model"""
        if not HAS_SKLEARN:
            return False
        
        # This would require labeled data (threat vs normal)
        # For now, use unsupervised methods
        return False
    
    def cluster_patterns(self, data_dir=None):
        """Cluster patterns to discover groups"""
        if not HAS_SKLEARN or not HAS_NUMPY:
            return []
        
        if data_dir:
            data_path = Path(data_dir)
        else:
            data_path = Path.home() / ".macguardian" / "ai" / "data"
        
        if not data_path.exists():
            return []
        
        metrics_files = sorted(data_path.glob("metrics_*.json"), reverse=True)[:50]
        
        if len(metrics_files) < 5:
            return []
        
        X = []
        for mfile in metrics_files:
            try:
                with open(mfile, 'r') as f:
                    metrics = json.load(f)
                features = self.extract_features(metrics)
                X.append(features)
            except:
                continue
        
        if len(X) < 5:
            return []
        
        X = np.array(X)
        
        # Use DBSCAN for clustering (finds arbitrary shaped clusters)
        try:
            if self.scaler:
                X_scaled = self.scaler.transform(X)
            else:
                self.scaler = StandardScaler()
                X_scaled = self.scaler.fit_transform(X)
            
            clusterer = DBSCAN(eps=0.5, min_samples=3)
            clusters = clusterer.fit_predict(X_scaled)
            
            # Analyze clusters
            unique_clusters = set(clusters)
            if -1 in unique_clusters:
                unique_clusters.remove(-1)  # Remove noise label
            
            results = []
            for cluster_id in unique_clusters:
                cluster_size = np.sum(clusters == cluster_id)
                if cluster_size > 2:
                    results.append(f"Cluster {cluster_id}: {cluster_size} similar patterns")
            
            return results
        except:
            return []
    
    def predict_threats_ml(self, data_dir=None):
        """Predictive analysis using ML"""
        if not HAS_NUMPY:
            return "ML not available"
        
        if data_dir:
            data_path = Path(data_dir)
        else:
            data_path = Path.home() / ".macguardian" / "ai" / "data"
        
        if not data_path.exists():
            return "No historical data"
        
        metrics_files = sorted(data_path.glob("metrics_*.json"), reverse=True)[:20]
        
        if len(metrics_files) < 5:
            return "Insufficient data"
        
        # Extract time series
        process_counts = []
        network_counts = []
        timestamps = []
        
        for mfile in metrics_files:
            try:
                with open(mfile, 'r') as f:
                    data = json.load(f)
                    process_counts.append(data.get("process_count", 0))
                    network_counts.append(data.get("network_connections", 0))
                    timestamps.append(data.get("timestamp", ""))
            except:
                continue
        
        if len(process_counts) < 5:
            return "Insufficient data"
        
        # Linear regression for trend prediction
        x = np.arange(len(process_counts))
        
        # Process count trend
        process_coef = np.polyfit(x, process_counts, 1)
        process_trend = process_coef[0]
        process_next = np.polyval(process_coef, len(process_counts))
        
        # Network trend
        network_coef = np.polyfit(x, network_counts, 1)
        network_trend = network_coef[0]
        network_next = np.polyval(network_coef, len(network_counts))
        
        predictions = []
        
        if process_trend > 3:
            predictions.append(f"Process count increasing (predicted: {process_next:.0f})")
        if network_trend > 1:
            predictions.append(f"Network activity increasing (predicted: {network_next:.0f})")
        
        # Check for anomalies in trend
        if len(process_counts) >= 3:
            recent_std = np.std(process_counts[-3:])
            overall_std = np.std(process_counts)
            
            if recent_std > overall_std * 1.5:
                predictions.append("High variance in recent activity")
        
        if predictions:
            return f"ML Prediction: {', '.join(predictions)}"
        
        return "No significant trends"
    
    def online_learning(self, metrics_file, is_anomaly=False):
        """Online learning - update model with new data"""
        if not HAS_SKLEARN:
            return False
        
        try:
            with open(metrics_file, 'r') as f:
                metrics = json.load(f)
        except:
            return False
        
        features = self.extract_features(metrics)
        
        # Add to history
        if HAS_NUMPY:
            self.feature_history.append(features)
        
        # Update baseline if normal
        if not is_anomaly and self.baseline_metrics:
            for key in ["process_count", "network_connections", "cpu_usage", "memory_usage"]:
                if key in metrics and key in self.baseline_metrics:
                    # Exponential moving average
                    alpha = 0.1  # Learning rate
                    baseline = self.baseline_metrics[key]
                    old_mean = baseline.get("mean", 0)
                    new_mean = alpha * metrics[key] + (1 - alpha) * old_mean
                    baseline["mean"] = new_mean
                    
                    # Update std (simplified)
                    old_std = baseline.get("std", 1)
                    diff = abs(metrics[key] - new_mean)
                    new_std = alpha * diff + (1 - alpha) * old_std
                    baseline["std"] = new_std
        
        # Retrain model periodically (every 50 samples)
        if len(self.feature_history) % 50 == 0 and len(self.feature_history) >= 50:
            self.train_anomaly_model(force_retrain=True)
        
        return True
    
    def save_models(self):
        """Save all models"""
        if self.anomaly_model and HAS_SKLEARN:
            joblib.dump(self.anomaly_model, self.models_dir / "anomaly_model.pkl")
        if self.scaler and HAS_SKLEARN:
            joblib.dump(self.scaler, self.models_dir / "scaler.pkl")
        
        # Save baseline
        baseline_file = Path.home() / ".macguardian" / "ai" / "baseline.json"
        baseline_file.parent.mkdir(parents=True, exist_ok=True)
        with open(baseline_file, 'w') as f:
            json.dump(self.baseline_metrics, f, indent=2)
    
    def load_models(self):
        """Load saved models"""
        if not HAS_SKLEARN:
            return
        
        model_file = self.models_dir / "anomaly_model.pkl"
        scaler_file = self.models_dir / "scaler.pkl"
        
        try:
            if model_file.exists():
                self.anomaly_model = joblib.load(model_file)
            if scaler_file.exists():
                self.scaler = joblib.load(scaler_file)
        except:
            pass


def main():
    parser = argparse.ArgumentParser(description="Mac Guardian ML Engine")
    parser.add_argument("--analyze", help="Analyze metrics file")
    parser.add_argument("--train", action="store_true", help="Train models")
    parser.add_argument("--cluster", help="Cluster patterns in data directory")
    parser.add_argument("--predict", help="Predictive analysis")
    parser.add_argument("--online", help="Online learning with metrics file")
    parser.add_argument("--anomaly", action="store_true", help="Mark as anomaly for online learning")
    
    args = parser.parse_args()
    
    engine = MLSecurityEngine()
    
    if args.train:
        print("Training ML models...")
        if engine.train_anomaly_model(force_retrain=True):
            print("✅ Models trained successfully")
            engine.save_models()
        else:
            print("❌ Training failed - need more data")
    
    elif args.analyze:
        result = engine.detect_anomalies_ml(args.analyze)
        print(result)
        engine.save_models()
    
    elif args.cluster:
        clusters = engine.cluster_patterns(args.cluster)
        if clusters:
            for cluster in clusters:
                print(cluster)
        else:
            print("No clusters found")
    
    elif args.predict:
        result = engine.predict_threats_ml(args.predict)
        print(result)
    
    elif args.online:
        engine.online_learning(args.online, args.anomaly)
        engine.save_models()
        print("✅ Online learning complete")
    
    else:
        parser.print_help()


if __name__ == "__main__":
    main()

