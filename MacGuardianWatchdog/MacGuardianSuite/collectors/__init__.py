"""
Collector modules for MacGuardian
All collectors implement a standard interface
"""

from abc import ABC, abstractmethod

class CollectorModule(ABC):
    """Base class for all collector modules"""
    
    @abstractmethod
    def initialize(self, config: dict):
        """Initialize the module with configuration"""
        pass
    
    @abstractmethod
    def start(self):
        """Start collecting events"""
        pass
    
    @abstractmethod
    def stop(self):
        """Stop collecting events"""
        pass
    
    @abstractmethod
    def get_status(self) -> dict:
        """Return module status"""
        pass

