#!/usr/bin/env python3

"""
DNS Collector
Collects DNS query information
"""

import json
import sys
import subprocess
from datetime import datetime
from typing import List, Dict, Any

def get_dns_servers() -> List[str]:
    """Get DNS servers from /etc/resolv.conf"""
    dns_servers = []
    
    try:
        with open('/etc/resolv.conf', 'r') as f:
            for line in f:
                if line.startswith('nameserver'):
                    parts = line.split()
                    if len(parts) > 1:
                        dns_servers.append(parts[1])
    except IOError:
        pass
    
    return dns_servers

def get_dns_cache() -> List[Dict[str, Any]]:
    """Get DNS cache entries (if accessible)"""
    cache_entries = []
    
    # macOS DNS cache is not easily accessible without root
    # This is a placeholder for future implementation
    return cache_entries

def main():
    """Main function"""
    output_file = sys.argv[1] if len(sys.argv) > 1 else '/tmp/dns_info.json'
    
    dns_servers = get_dns_servers()
    cache_entries = get_dns_cache()
    
    data = {
        'timestamp': datetime.utcnow().isoformat() + 'Z',
        'dns_servers': dns_servers,
        'cache_entries': cache_entries
    }
    
    with open(output_file, 'w') as f:
        json.dump(data, f, indent=2)
    
    print(f"DNS info collected: {len(dns_servers)} DNS servers")
    print(f"Output: {output_file}")

if __name__ == '__main__':
    main()

