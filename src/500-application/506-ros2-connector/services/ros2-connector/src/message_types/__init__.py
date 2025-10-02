"""
Message type registry for automatic discovery of message handlers.

This module exposes the message type registry functionality.
"""

from .registry import (
    MessageTypeRegistry,
    get_registry,
    get_supported_types,
    create_handler
)

__all__ = [
    'MessageTypeRegistry',
    'get_registry',
    'get_supported_types',
    'create_handler'
]
