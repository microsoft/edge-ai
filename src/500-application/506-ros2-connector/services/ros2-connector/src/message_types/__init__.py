"""
Message type registry for automatic discovery of message handlers.

This module exposes the message type registry functionality.
"""

from .registry import MessageTypeRegistry, create_handler, get_registry, get_supported_types

__all__ = [
    'MessageTypeRegistry',
    'get_registry',
    'get_supported_types',
    'create_handler'
]
