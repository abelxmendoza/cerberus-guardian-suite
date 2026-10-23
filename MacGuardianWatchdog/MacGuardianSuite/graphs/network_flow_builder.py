#!/usr/bin/env python3

"""
Network Flow Graph Builder
Builds graph visualization data from network connections
"""

import json
import sys
import subprocess
import re
from datetime import datetime
from typing import Dict, List, Any

def get_network_connections() -> List[Dict[str, Any]]:
    """Get network connections using lsof"""
    connections = []
    
    try:
        result = subprocess.run(
            ['lsof', '-i', '-P', '-n'],
            capture_output=True,
            text=True,
            timeout=10
        )
        
        if result.returncode != 0:
            return connections
        
        for line in result.stdout.split('\n')[1:]:  # Skip header
            if not line.strip():
                continue
            
            parts = line.split()
            if len(parts) < 9:
                continue
            
            try:
                process = parts[0]
                pid = parts[1]
                connection_info = parts[8]
                
                # Parse connection (e.g., "192.168.1.1:443")
                if '->' in connection_info:
                    local, remote = connection_info.split('->')
                else:
                    local = connection_info
                    remote = ""
                
                # Extract IP and port
                local_match = re.match(r'([^:]+):(\d+)', local)
                remote_match = re.match(r'([^:]+):(\d+)', remote) if remote else None
                
                if local_match:
                    local_ip = local_match.group(1)
                    local_port = int(local_match.group(2))
                    
                    remote_ip = ""
                    remote_port = 0
                    if remote_match:
                        remote_ip = remote_match.group(1)
                        remote_port = int(remote_match.group(2))
                    
                    connections.append({
                        'process': process,
                        'pid': pid,
                        'local_ip': local_ip,
                        'local_port': local_port,
                        'remote_ip': remote_ip,
                        'remote_port': remote_port
                    })
            except (ValueError, IndexError):
                continue
                
    except subprocess.TimeoutExpired:
        pass
    except Exception as e:
        print(f"Error getting network connections: {e}", file=sys.stderr)
    
    return connections

def build_network_graph() -> Dict[str, Any]:
    """Build network flow graph"""
    connections = get_network_connections()
    
    nodes = []
    edges = []
    node_ids = {}
    node_counter = 0
    
    # Create nodes and edges
    for conn in connections:
        # Process node
        process_id = f"process_{conn['pid']}"
        if process_id not in node_ids:
            node_ids[process_id] = node_counter
            nodes.append({
                'id': node_counter,
                'label': f"{conn['process']} (PID {conn['pid']})",
                'type': 'process',
                'pid': conn['pid']
            })
            node_counter += 1
        
        # Local IP node
        if conn['local_ip'] and conn['local_ip'] not in ['*', 'localhost']:
            local_ip_id = f"ip_{conn['local_ip']}"
            if local_ip_id not in node_ids:
                node_ids[local_ip_id] = node_counter
                nodes.append({
                    'id': node_counter,
                    'label': conn['local_ip'],
                    'type': 'ip',
                    'ip': conn['local_ip']
                })
                node_counter += 1
            
            # Edge: Process -> Local IP
            edges.append({
                'from': node_ids[process_id],
                'to': node_ids[local_ip_id],
                'label': f"Port {conn['local_port']}",
                'port': conn['local_port']
            })
        
        # Remote IP node
        if conn['remote_ip']:
            remote_ip_id = f"ip_{conn['remote_ip']}"
            if remote_ip_id not in node_ids:
                node_ids[remote_ip_id] = node_counter
                nodes.append({
                    'id': node_counter,
                    'label': conn['remote_ip'],
                    'type': 'ip',
                    'ip': conn['remote_ip']
                })
                node_counter += 1
            
            # Edge: Local IP -> Remote IP
            if conn['local_ip'] and conn['local_ip'] not in ['*', 'localhost']:
                local_ip_id = f"ip_{conn['local_ip']}"
                if local_ip_id in node_ids:
                    edges.append({
                        'from': node_ids[local_ip_id],
                        'to': node_ids[remote_ip_id],
                        'label': f"{conn['local_port']} -> {conn['remote_port']}",
                        'local_port': conn['local_port'],
                        'remote_port': conn['remote_port']
                    })
    
    return {
        'timestamp': datetime.utcnow().isoformat() + 'Z',
        'nodes': nodes,
        'edges': edges,
        'connection_count': len(connections)
    }

def main():
    """Main function"""
    output_file = sys.argv[1] if len(sys.argv) > 1 else '/tmp/network_graph.json'
    
    graph = build_network_graph()
    
    with open(output_file, 'w') as f:
        json.dump(graph, f, indent=2)
    
    print(f"Network graph built: {len(graph['nodes'])} nodes, {len(graph['edges'])} edges")
    print(f"Output: {output_file}")

if __name__ == '__main__':
    main()

