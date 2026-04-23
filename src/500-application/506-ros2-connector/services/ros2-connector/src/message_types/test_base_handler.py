"""Unit tests for BaseMessageHandler pure methods."""

import json
import time
from unittest.mock import MagicMock

import pytest
from base_handler import BaseMessageHandler


class ConcreteHandler(BaseMessageHandler):
    """Minimal concrete subclass for testing the abstract base."""

    message_type = "test_msgs/msg/Test"
    message_class = None
    handler_type = "test"

    def handle_message(self, msg, topic_name, logger, mqtt_publisher):
        data = self.create_base_mqtt_data(topic_name)
        data["payload"] = str(msg)
        self.publish_to_mqtt(topic_name, data, mqtt_publisher)


@pytest.fixture
def handler():
    return ConcreteHandler(mqtt_topic_prefix="robot")


class TestFormatMqttTopic:
    def test_basic_topic_formatting(self, handler):
        result = handler.format_mqtt_topic("/cmd_vel")
        assert result == "robot/test_cmd_vel"

    def test_slashes_replaced_with_underscores(self, handler):
        result = handler.format_mqtt_topic("/a/b/c")
        assert result == "robot/test_a_b_c"

    def test_empty_topic(self, handler):
        result = handler.format_mqtt_topic("")
        assert result == "robot/test"

    def test_custom_prefix(self):
        h = ConcreteHandler(mqtt_topic_prefix="edge/device")
        result = h.format_mqtt_topic("/sensor")
        assert result == "edge/device/test_sensor"


class TestCreateBaseMqttData:
    def test_contains_required_keys(self, handler):
        handler.message_counts["/topic"] = 5
        data = handler.create_base_mqtt_data("/topic")
        assert set(data.keys()) == {"topic", "type", "count", "timestamp"}

    def test_topic_preserved(self, handler):
        handler.message_counts["/vel"] = 0
        data = handler.create_base_mqtt_data("/vel")
        assert data["topic"] == "/vel"

    def test_handler_type_set(self, handler):
        data = handler.create_base_mqtt_data("/x")
        assert data["type"] == "test"

    def test_count_reflects_message_counts(self, handler):
        handler.message_counts["/t"] = 42
        data = handler.create_base_mqtt_data("/t")
        assert data["count"] == 42

    def test_count_defaults_to_zero_for_unknown_topic(self, handler):
        data = handler.create_base_mqtt_data("/never_seen")
        assert data["count"] == 0

    def test_timestamp_is_recent(self, handler):
        before = time.time()
        data = handler.create_base_mqtt_data("/t")
        after = time.time()
        assert before <= data["timestamp"] <= after


class TestCreateCallback:
    def test_callback_increments_count(self, handler):
        cb = handler.create_callback("/topic", MagicMock(), MagicMock())
        assert handler.message_counts["/topic"] == 0
        cb("msg1")
        assert handler.message_counts["/topic"] == 1
        cb("msg2")
        assert handler.message_counts["/topic"] == 2

    def test_callback_calls_handle_message(self, handler):
        publisher = MagicMock()
        cb = handler.create_callback("/topic", MagicMock(), publisher)
        cb("hello")
        publisher.assert_called_once()

    def test_independent_topic_counters(self, handler):
        handler.create_callback("/a", MagicMock(), MagicMock())("/m")
        handler.create_callback("/b", MagicMock(), MagicMock())
        assert handler.message_counts["/a"] == 1
        assert handler.message_counts["/b"] == 0


class TestPublishToMqtt:
    def test_publishes_to_formatted_topic(self, handler):
        publisher = MagicMock()
        handler.publish_to_mqtt("/cmd_vel", {"key": "val"}, publisher)
        topic_arg = publisher.call_args[0][0]
        assert topic_arg == "robot/test_cmd_vel"

    def test_publishes_valid_json(self, handler):
        publisher = MagicMock()
        data = {"topic": "/x", "type": "test", "count": 0, "timestamp": 1.0}
        handler.publish_to_mqtt("/x", data, publisher)
        json_arg = publisher.call_args[0][1]
        parsed = json.loads(json_arg)
        assert parsed == data
