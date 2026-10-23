#!/usr/bin/env python3
"""
Local Output Module - Store events locally in JSONL format
"""

import json
from pathlib import Path
from typing import List, Dict
from datetime import datetime


class LocalOutput:
    """
    Output module for local storage.
    Writes events to JSONL files.
    """
    
    def __init__(self, config: Dict):
        self.config = config
        self.enabled = config.get("enabled", True)
        self.format = config.get("format", "jsonl")
        self.path = Path(config.get("path", "~/.macguardian/events")).expanduser()
        self.path.mkdir(parents=True, exist_ok=True)
        
        # Current file
        self.current_file = None
        self.file_size = 0
        self.max_file_size = 10 * 1024 * 1024  # 10MB
        
    def __call__(self, events: List[Dict]):
        """Handle batch of events (called by event bus)"""
        if not self.enabled:
            return
        
        # Get current file
        if not self.current_file or self.file_size >= self.max_file_size:
            self._rotate_file()
        
        # Write events
        with open(self.current_file, "a") as f:
            for event in events:
                f.write(json.dumps(event) + "\n")
                self.file_size += len(json.dumps(event)) + 1
    
    def _rotate_file(self):
        """Rotate to a new file"""
        timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
        self.current_file = self.path / f"events_{timestamp}.jsonl"
        self.file_size = 0

