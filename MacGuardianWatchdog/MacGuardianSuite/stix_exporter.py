#!/usr/bin/env python3

# ===============================
# STIX Format Exporter
# Exports IOCs and threat data in STIX 2.1 format
# ===============================

import json
import sys
from datetime import datetime
from uuid import uuid4

def create_stix_bundle(observables, indicators=None):
    """
    Create a STIX 2.1 bundle with observables and indicators
    
    Args:
        observables: List of observable objects (IPs, domains, hashes, etc.)
        indicators: List of indicator objects (optional)
    
    Returns:
        STIX bundle as dict
    """
    bundle = {
        "type": "bundle",
        "id": f"bundle--{uuid4()}",
        "spec_version": "2.1",
        "objects": []
    }
    
    # Add identity (your organization)
    identity = {
        "type": "identity",
        "id": f"identity--{uuid4()}",
        "spec_version": "2.1",
        "name": "MacGuardian Suite",
        "identity_class": "organization",
        "created": datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S.%fZ"),
        "modified": datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S.%fZ")
    }
    bundle["objects"].append(identity)
    
    # Add observables
    for obs in observables:
        observable = {
            "type": "observed-data",
            "id": f"observed-data--{uuid4()}",
            "spec_version": "2.1",
            "created": datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S.%fZ"),
            "modified": datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S.%fZ"),
            "first_observed": obs.get("first_observed", datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S.%fZ")),
            "last_observed": obs.get("last_observed", datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S.%fZ")),
            "number_observed": obs.get("number_observed", 1),
            "objects": {
                "0": obs["object"]
            }
        }
        bundle["objects"].append(observable)
    
    # Add indicators if provided
    if indicators:
        for ind in indicators:
            indicator = {
                "type": "indicator",
                "id": f"indicator--{uuid4()}",
                "spec_version": "2.1",
                "created": datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S.%fZ"),
                "modified": datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S.%fZ"),
                "pattern": ind.get("pattern", ""),
                "pattern_type": "stix",
                "pattern_version": "2.1",
                "valid_from": datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S.%fZ"),
                "labels": ind.get("labels", ["malicious-activity"]),
                "kill_chain_phases": ind.get("kill_chain_phases", [])
            }
            bundle["objects"].append(indicator)
    
    return bundle

def ip_to_stix(ip_address, malicious=True):
    """Convert IP address to STIX observable"""
    return {
        "object": {
            "type": "ipv4-addr",
            "value": ip_address
        },
        "first_observed": datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S.%fZ"),
        "labels": ["malicious-activity"] if malicious else ["suspicious-activity"]
    }

def domain_to_stix(domain, malicious=True):
    """Convert domain to STIX observable"""
    return {
        "object": {
            "type": "domain-name",
            "value": domain
        },
        "first_observed": datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S.%fZ"),
        "labels": ["malicious-activity"] if malicious else ["suspicious-activity"]
    }

def hash_to_stix(file_hash, hash_type="SHA-256"):
    """Convert file hash to STIX observable"""
    hash_type_lower = hash_type.lower().replace("-", "")
    return {
        "object": {
            "type": "file",
            "hashes": {
                hash_type_lower: file_hash
            }
        },
        "first_observed": datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S.%fZ"),
        "labels": ["malicious-activity"]
    }

def url_to_stix(url, malicious=True):
    """Convert URL to STIX observable"""
    return {
        "object": {
            "type": "url",
            "value": url
        },
        "first_observed": datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S.%fZ"),
        "labels": ["malicious-activity"] if malicious else ["suspicious-activity"]
    }

def export_iocs_to_stix(ioc_file, output_file):
    """
    Export IOCs from JSON file to STIX format
    
    Args:
        ioc_file: Path to IOC JSON file
        output_file: Path to output STIX JSON file
    """
    try:
        with open(ioc_file, 'r') as f:
            iocs = json.load(f)
    except FileNotFoundError:
        print(f"Error: IOC file not found: {ioc_file}")
        return False
    except json.JSONDecodeError:
        print(f"Error: Invalid JSON in {ioc_file}")
        return False
    
    observables = []
    
    # Convert IOCs to STIX observables
    for ioc in iocs:
        ioc_type = ioc.get("type", "").lower()
        value = ioc.get("value", "")
        malicious = ioc.get("malicious", True)
        
        if ioc_type == "ip":
            observables.append(ip_to_stix(value, malicious))
        elif ioc_type == "domain":
            observables.append(domain_to_stix(value, malicious))
        elif ioc_type in ["hash", "sha256", "md5"]:
            observables.append(hash_to_stix(value, "SHA-256" if "sha" in ioc_type else "MD5"))
        elif ioc_type == "url":
            observables.append(url_to_stix(value, malicious))
    
    # Create STIX bundle
    bundle = create_stix_bundle(observables)
    
    # Write to file
    with open(output_file, 'w') as f:
        json.dump(bundle, f, indent=2)
    
    print(f"✅ Exported {len(observables)} IOCs to STIX format: {output_file}")
    return True

def main():
    if len(sys.argv) < 3:
        print("Usage: stix_exporter.py <ioc_file.json> <output.stix.json>")
        print("\nExample:")
        print("  stix_exporter.py ~/.macguardian/iocs.json ~/.macguardian/iocs.stix.json")
        sys.exit(1)
    
    ioc_file = sys.argv[1]
    output_file = sys.argv[2]
    
    if export_iocs_to_stix(ioc_file, output_file):
        sys.exit(0)
    else:
        sys.exit(1)

if __name__ == "__main__":
    main()

