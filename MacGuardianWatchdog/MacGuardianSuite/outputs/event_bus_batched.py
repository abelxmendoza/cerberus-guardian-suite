#!/usr/bin/env python3
"""
High-performance Event Bus with batching, compression, and deduplication
Handles 5,000+ events/minute with minimal CPU overhead
"""

import asyncio
import json
import gzip
import base64
import socket
import websockets
from collections import deque
from datetime import datetime, timedelta
from typing import Dict, Set, List, Optional
import hashlib

# Configuration
BATCH_SIZE = 50  # Events per batch
BATCH_INTERVAL = 0.1  # 100ms batching window
COMPRESS_THRESHOLD = 1024  # Compress contexts larger than 1KB
DEDUP_WINDOW = timedelta(seconds=5)  # Deduplicate events within 5 seconds

class EventBusBatched:
    """High-performance Event Bus with batching and compression"""
    
    def __init__(self, uds_path: str = "/tmp/macguardian.sock", ws_port: int = 9765):
        self.uds_path = uds_path
        self.ws_port = ws_port
        self.clients: Set[websockets.WebSocketServerProtocol] = set()
        self.event_buffer: deque = deque(maxlen=1000)
        self.batch_task: Optional[asyncio.Task] = None
        self.recent_hashes: Dict[str, datetime] = {}  # For deduplication
        
    async def start(self):
        """Start the event bus servers"""
        # Start Unix Domain Socket server
        uds_server = await asyncio.start_unix_server(
            self.handle_uds_client,
            path=self.uds_path
        )
        
        # Start WebSocket server
        ws_server = await websockets.serve(
            self.handle_ws_client,
            "localhost",
            self.ws_port
        )
        
        # Start batch processor
        self.batch_task = asyncio.create_task(self.batch_processor())
        
        print(f"✅ Event Bus started: UDS={self.uds_path}, WS=ws://localhost:{self.ws_port}")
        
        # Keep running
        await asyncio.gather(
            uds_server.serve_forever(),
            ws_server.wait_closed()
        )
    
    async def handle_uds_client(self, reader: asyncio.StreamReader, writer: asyncio.StreamWriter):
        """Handle Unix Domain Socket client"""
        try:
            while True:
                data = await reader.read(65536)  # 64KB max
                if not data:
                    break
                
                try:
                    event = json.loads(data.decode('utf-8'))
                    await self.process_event(event)
                except json.JSONDecodeError as e:
                    print(f"⚠️ Invalid JSON: {e}")
        except Exception as e:
            print(f"⚠️ UDS client error: {e}")
        finally:
            writer.close()
            await writer.wait_closed()
    
    async def handle_ws_client(self, websocket: websockets.WebSocketServerProtocol, path: str):
        """Handle WebSocket client"""
        self.clients.add(websocket)
        try:
            await websocket.wait_closed()
        finally:
            self.clients.remove(websocket)
    
    async def process_event(self, event: Dict):
        """Process incoming event with deduplication"""
        # Generate event hash for deduplication
        event_hash = self._hash_event(event)
        
        # Check if duplicate
        if event_hash in self.recent_hashes:
            event_time = datetime.fromisoformat(event.get('timestamp', '').replace('Z', '+00:00'))
            if event_time - self.recent_hashes[event_hash] < DEDUP_WINDOW:
                return  # Skip duplicate
        
        # Store hash and timestamp
        event_time = datetime.fromisoformat(event.get('timestamp', '').replace('Z', '+00:00'))
        self.recent_hashes[event_hash] = event_time
        
        # Clean old hashes
        cutoff = datetime.utcnow() - DEDUP_WINDOW
        self.recent_hashes = {
            h: t for h, t in self.recent_hashes.items()
            if t > cutoff
        }
        
        # Compress large contexts
        if 'context' in event:
            context_str = json.dumps(event['context'])
            if len(context_str) > COMPRESS_THRESHOLD:
                compressed = gzip.compress(context_str.encode('utf-8'))
                event['context_compressed'] = base64.b64encode(compressed).decode('utf-8')
                event['context'] = None  # Remove original to save space
        
        # Add to buffer
        self.event_buffer.append(event)
    
    async def batch_processor(self):
        """Process events in batches"""
        while True:
            await asyncio.sleep(BATCH_INTERVAL)
            
            if len(self.event_buffer) == 0:
                continue
            
            # Extract batch
            batch = []
            batch_size = min(BATCH_SIZE, len(self.event_buffer))
            for _ in range(batch_size):
                if self.event_buffer:
                    batch.append(self.event_buffer.popleft())
            
            if batch:
                await self.broadcast_batch(batch)
    
    async def broadcast_batch(self, batch: List[Dict]):
        """Broadcast batch to all WebSocket clients"""
        if not self.clients:
            return
        
        # Serialize batch
        batch_json = json.dumps({
            'type': 'batch',
            'count': len(batch),
            'events': batch,
            'timestamp': datetime.utcnow().isoformat() + 'Z'
        })
        
        # Broadcast to all clients in parallel
        if self.clients:
            await asyncio.gather(
                *[self._send_to_client(client, batch_json) for client in self.clients],
                return_exceptions=True
            )
    
    async def _send_to_client(self, client: websockets.WebSocketServerProtocol, message: str):
        """Send message to a single client"""
        try:
            await client.send(message)
        except Exception as e:
            print(f"⚠️ Failed to send to client: {e}")
            self.clients.discard(client)
    
    def _hash_event(self, event: Dict) -> str:
        """Generate hash for event deduplication"""
        # Hash based on event_id, type, and key context fields
        key_fields = {
            'event_id': event.get('event_id', ''),
            'event_type': event.get('event_type', ''),
            'source': event.get('source', ''),
        }
        
        # Include relevant context fields
        if 'context' in event and isinstance(event['context'], dict):
            key_fields['context_keys'] = sorted(event['context'].keys())
        
        hash_str = json.dumps(key_fields, sort_keys=True)
        return hashlib.sha256(hash_str.encode('utf-8')).hexdigest()

async def main():
    """Main entry point"""
    bus = EventBusBatched()
    await bus.start()

if __name__ == '__main__':
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n🛑 Event Bus stopped")

