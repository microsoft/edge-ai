"""
Message type registry for automatic discovery of message handlers.

This module automatically discovers and registers all message type handlers
in the message_types folder.
"""

import os
import importlib
import inspect
from typing import Dict, Type

# Import base handler using relative import
from . import base_handler
BaseMessageHandler = base_handler.BaseMessageHandler


class MessageTypeRegistry:
    """Registry for message type handlers with automatic discovery."""

    def __init__(self):
        """Initialize the registry and discover handlers."""
        self.handlers: Dict[str, Type[BaseMessageHandler]] = {}
        self.discover_handlers()

    def discover_handlers(self) -> None:
        """
        Automatically discover and register message handlers.

        Scans the message_types directory for Python modules and imports
        any classes that inherit from BaseMessageHandler.
        """
        current_dir = os.path.dirname(__file__)

        # Find all Python files in the current directory
        for filename in os.listdir(current_dir):
            if (filename.endswith('.py') and
                    filename != '__init__.py' and
                    filename != 'base_handler.py' and
                    filename != 'registry.py'):

                module_name = filename[:-3]  # Remove .py extension

                try:
                    # Import the module using relative import
                    module = importlib.import_module(
                        f'.{module_name}', package='message_types'
                    )
                except ImportError as e:
                    print(f"Failed to import module {module_name}: {e}")
                    continue

                # Find classes that inherit from BaseMessageHandler
                for name, obj in inspect.getmembers(module):
                    if (inspect.isclass(obj) and
                            issubclass(obj, BaseMessageHandler) and
                            obj != BaseMessageHandler):
                        # Access class-level message_type without instantiation
                        message_type = getattr(obj, 'message_type', None)
                        if isinstance(message_type, str) and message_type:
                            self.handlers[message_type] = obj
                            print(
                                f"Registered handler: {name} for "
                                f"{message_type}"
                            )
                        else:
                            print(
                                f"Skipped handler {name}: missing "
                                f"class attribute 'message_type'"
                            )

    def get_handler(self, message_type: str) -> Type[BaseMessageHandler]:
        """
        Get a handler class for the specified message type.

        Args:
            message_type: The ROS2 message type string

        Returns:
            Handler class for the message type

        Raises:
            KeyError: If no handler is found for the message type
        """
        if message_type not in self.handlers:
            raise KeyError(f"No handler found for message type: "
                           f"{message_type}")

        return self.handlers[message_type]

    def get_all_handlers(self) -> Dict[str, Type[BaseMessageHandler]]:
        """
        Get all registered handlers.

        Returns:
            Dictionary mapping message types to handler classes
        """
        return self.handlers.copy()

    def is_supported(self, message_type: str) -> bool:
        """
        Check if a message type is supported.

        Args:
            message_type: The ROS2 message type string

        Returns:
            True if the message type is supported, False otherwise
        """
        return message_type in self.handlers


# Global registry instance
_registry = MessageTypeRegistry()


def get_registry() -> MessageTypeRegistry:
    """
    Get the global message type registry.

    Returns:
        The global MessageTypeRegistry instance
    """
    return _registry


def get_supported_types() -> Dict[str, Type[BaseMessageHandler]]:
    """
    Get all supported message types and their handlers.

    Returns:
        Dictionary mapping message types to handler classes
    """
    return _registry.get_all_handlers()


def create_handler(
    message_type: str,
    mqtt_topic_prefix: str = "robot"
) -> BaseMessageHandler:
    """
    Create a handler instance for the specified message type.

    Args:
        message_type: The ROS2 message type string
        mqtt_topic_prefix: Prefix for MQTT topics

    Returns:
        Handler instance for the message type

    Raises:
        KeyError: If no handler is found for the message type
    """
    handler_class = _registry.get_handler(message_type)
    return handler_class(mqtt_topic_prefix)
