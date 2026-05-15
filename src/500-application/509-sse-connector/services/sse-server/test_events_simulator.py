"""Unit tests for AnalyticsEventSimulator event generation methods."""

import pytest
from events_simulator import AnalyticsEventSimulator


@pytest.fixture
def simulator():
    return AnalyticsEventSimulator(
        device_id="test-cam-001",
        heartbeat_interval=5,
        alert_probability=0.5,
    )


FIXED_TS = 1_700_000_000_000


class TestGenerateHeartbeatEvent:
    def test_returns_heartbeat_type(self, simulator):
        event = simulator.generate_heartbeat_event(FIXED_TS)
        assert event["type"] == "HEARTBEAT"

    def test_returns_correct_timestamp(self, simulator):
        event = simulator.generate_heartbeat_event(FIXED_TS)
        assert event["timestamp"] == FIXED_TS

    def test_contains_only_expected_keys(self, simulator):
        event = simulator.generate_heartbeat_event(FIXED_TS)
        assert set(event.keys()) == {"type", "timestamp"}


class TestGenerateAnalyticsEnabledEvent:
    def test_returns_enabled_type(self, simulator):
        event = simulator.generate_analytics_enabled_event(FIXED_TS)
        assert event["type"] == "ANALYTICS_ENABLED"

    def test_includes_analytics_type(self, simulator):
        event = simulator.generate_analytics_enabled_event(FIXED_TS)
        assert event["analytics_type"] == "leak detection"


class TestGenerateAnalyticsDisabledEvent:
    def test_returns_disabled_type(self, simulator):
        event = simulator.generate_analytics_disabled_event(FIXED_TS)
        assert event["type"] == "ANALYTICS_DISABLED"

    def test_includes_analytics_type(self, simulator):
        event = simulator.generate_analytics_disabled_event(FIXED_TS)
        assert event["analytics_type"] == "leak detection"


class TestGenerateBasicAlertEvent:
    def test_returns_alert_type(self, simulator):
        event = simulator.generate_basic_alert_event(FIXED_TS)
        assert event["type"] == "ALERT"

    def test_message_is_leak(self, simulator):
        event = simulator.generate_basic_alert_event(FIXED_TS)
        assert event["message"] == "leak"

    def test_event_id_increments(self, simulator):
        first = simulator.generate_basic_alert_event(FIXED_TS)
        second = simulator.generate_basic_alert_event(FIXED_TS)
        assert second["event_id"] == first["event_id"] + 1

    def test_event_id_starts_above_initial_counter(self, simulator):
        event = simulator.generate_basic_alert_event(FIXED_TS)
        assert event["event_id"] == 1001


class TestGenerateDetailedAlertEvent:
    def test_returns_alert_dlqc_type(self, simulator):
        event = simulator.generate_detailed_alert_event(FIXED_TS)
        assert event["type"] == "ALERT_DLQC"

    def test_contains_location_data(self, simulator):
        event = simulator.generate_detailed_alert_event(FIXED_TS)
        assert "leak_location" in event
        assert "longitude" in event["leak_location"]
        assert "latitude" in event["leak_location"]

    def test_contains_camera_metadata(self, simulator):
        event = simulator.generate_detailed_alert_event(FIXED_TS)
        assert "camera_id" in event
        assert "camera_location" in event
        assert "camera_orientation" in event
        assert "depression_angle" in event

    def test_contains_environmental_data(self, simulator):
        event = simulator.generate_detailed_alert_event(FIXED_TS)
        assert "wind_speed" in event
        assert "temperature" in event
        assert "humidity" in event

    def test_contains_flow_measurements(self, simulator):
        event = simulator.generate_detailed_alert_event(FIXED_TS)
        assert "flow_rate" in event
        assert event["unit"] == "g/s"
        assert "mass" in event
        assert event["mass_unit"] == "kg"

    def test_event_id_increments_across_types(self, simulator):
        basic = simulator.generate_basic_alert_event(FIXED_TS)
        detailed = simulator.generate_detailed_alert_event(FIXED_TS)
        assert detailed["event_id"] == basic["event_id"] + 1

    def test_latitude_in_valid_range(self, simulator):
        for _ in range(20):
            event = simulator.generate_detailed_alert_event(FIXED_TS)
            assert -90 <= event["leak_location"]["latitude"] <= 90

    def test_confidence_level_in_valid_range(self, simulator):
        for _ in range(20):
            event = simulator.generate_detailed_alert_event(FIXED_TS)
            assert 20 <= event["confidence_level"] <= 95
