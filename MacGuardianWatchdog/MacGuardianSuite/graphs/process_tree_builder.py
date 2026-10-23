#!/usr/bin/env python3

"""
Process Tree Builder
Builds process tree visualization data
"""

import json
import sys
import subprocess
import re
from datetime import datetime
from typing import Dict, List, Any

def get_process_tree() -> Dict[str, Any]:
    """Get process tree using ps"""
    processes = []
    
    try:
        result = subprocess.run(
            ['ps', 'axo', 'pid,ppid,comm,args'],
            capture_output=True,
            text=True,
            timeout=10
        )
        
        if result.returncode != 0:
            return {'nodes': [], 'edges': []}
        
        for line in result.stdout.split('\n')[1:]:  # Skip header
            if not line.strip():
                continue
            
            parts = line.split(None, 3)
            if len(parts) < 3:
                continue
            
            try:
                pid = int(parts[0])
                ppid = int(parts[1])
                comm = parts[2]
                args = parts[3] if len(parts) > 3 else comm
                
                processes.append({
                    'pid': pid,
                    'ppid': ppid,
                    'name': comm,
                    'args': args[:100]  # Limit args length
                })
            except (ValueError, IndexError):
                continue
                
    except subprocess.TimeoutExpired:
        pass
    except Exception as e:
        print(f"Error getting process tree: {e}", file=sys.stderr)
    
    # Build nodes and edges
    nodes = []
    edges = []
    pid_to_index = {}
    
    for idx, proc in enumerate(processes):
        pid_to_index[proc['pid']] = idx
        nodes.append({
            'id': idx,
            'label': f"{proc['name']} (PID {proc['pid']})",
            'pid': proc['pid'],
            'ppid': proc['ppid'],
            'name': proc['name']
        })
    
    # Create edges (parent -> child)
    for proc in processes:
        if proc['ppid'] in pid_to_index and proc['pid'] in pid_to_index:
            parent_idx = pid_to_index[proc['ppid']]
            child_idx = pid_to_index[proc['pid']]
            edges.append({
                'from': parent_idx,
                'to': child_idx
            })
    
    return {
        'timestamp': datetime.utcnow().isoformat() + 'Z',
        'nodes': nodes,
        'edges': edges,
        'process_count': len(processes)
    }

def main():
    """Main function"""
    output_file = sys.argv[1] if len(sys.argv) > 1 else '/tmp/process_tree.json'
    
    tree = get_process_tree()
    
    with open(output_file, 'w') as f:
        json.dump(tree, f, indent=2)
    
    print(f"Process tree built: {len(tree['nodes'])} nodes, {len(tree['edges'])} edges")
    print(f"Output: {output_file}")

if __name__ == '__main__':
    main()

