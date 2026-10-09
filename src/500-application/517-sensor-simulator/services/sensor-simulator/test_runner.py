"""Unit tests for MQTT callbacks, the reconnect loop, and process exit codes."""

import logging
import random
from types import SimpleNamespace

import app
import paho.mqtt.client as mqtt
import pytest
from app import Runner, SignalGenerator, SimulatorState, build_client
from models import SimulatorConfig
from paho.mqtt.packettypes import PacketTypes
from paho.mqtt.reasoncodes import ReasonCode

PLAIN = {"use_tls": False, "sat_file": None}


class FakeClient:
    """Stand-in for paho's Client that records calls instead of using a socket."""

    def __init__(self, **kwargs):
        self.kwargs = kwargs
        self.tls_ca_certs = "unset"
        self.message_callbacks = {}
        self.connect_properties = []
        self.fail_connect = False
        self.loop_results = []
        self.on_loop = None
        self.published = []
        self.subscriptions = []
        self.disconnects = 0
        self.on_connect = self.on_disconnect = self.on_publish = self.on_subscribe = None

    def tls_set(self, ca_certs=None):
        self.tls_ca_certs = ca_certs

    def message_callback_add(self, topic, callback):
        self.message_callbacks[topic] = callback

    def connect(self, host, port, keepalive, properties):
        self.connect_properties.append(properties)
        if self.fail_connect:
            raise ConnectionRefusedError("refused")

    def loop(self, timeout):
        if self.on_loop:
            self.on_loop()
        return self.loop_results.pop(0) if self.loop_results else mqtt.MQTT_ERR_SUCCESS

    def subscribe(self, topic, qos):
        self.subscriptions.append((topic, qos))

    def publish(self, topic, payload, qos, properties):
        self.published.append((topic, qos))
        return SimpleNamespace(rc=mqtt.MQTT_ERR_SUCCESS)

    def disconnect(self):
        self.disconnects += 1


class FakeClock:
    def __init__(self):
        self.now = 0.0

    def __call__(self):
        return self.now

    def sleep(self, seconds):
        self.now += seconds


def _connack(name="Success"):
    return ReasonCode(PacketTypes.CONNACK, name)


@pytest.fixture
def fake_client(monkeypatch):
    monkeypatch.setattr(app.mqtt, "Client", FakeClient)


def _runner(config):
    state = SimulatorState(inject_anomaly=config.inject_anomaly)
    client = build_client(config, state)
    clock = FakeClock()
    runner = Runner(config, client, state, SignalGenerator(config, random.Random(1)), clock, clock.sleep)
    return runner, client, state, clock


def _accept_connection(client):
    def on_loop():
        client.on_connect(client, None, {}, _connack(), None)
        client.on_loop = None

    client.on_loop = on_loop


@pytest.mark.usefixtures("fake_client")
class TestRunner:
    def test_token_is_reread_on_each_new_connection(self, tmp_path):
        token = tmp_path / "token"
        token.write_text("first", encoding="utf-8")
        runner, client, _, clock = _runner(SimulatorConfig(sat_file=str(token)))

        runner.step()
        client.loop_results.append(mqtt.MQTT_ERR_CONN_LOST)
        token.write_text("second", encoding="utf-8")
        runner.step()
        clock.now = runner.next_connect
        runner.step()

        assert [p.AuthenticationData for p in client.connect_properties] == [b"first", b"second"]

    def test_backoff_doubles_to_thirty_seconds_then_resets_after_connect(self):
        runner, client, state, clock = _runner(SimulatorConfig(**PLAIN))
        client.fail_connect = True
        delays = []
        for _ in range(7):
            attempt = runner.next_connect
            clock.now = attempt
            runner.step()
            delays.append(runner.next_connect - attempt)
        assert delays == [1, 2, 4, 8, 16, 30, 30]

        client.fail_connect = False
        _accept_connection(client)
        clock.now = runner.next_connect
        runner.step()
        assert state.connected
        assert runner.reconnect_delay == app.INITIAL_RECONNECT_DELAY
        assert state.counters.connects == 1

    def test_non_success_loop_result_reconnects(self):
        runner, client, state, clock = _runner(SimulatorConfig(**PLAIN))
        _accept_connection(client)
        runner.step()
        assert state.connected and runner.socket_open

        client.loop_results.append(mqtt.MQTT_ERR_CONN_LOST)
        runner.step()
        assert not state.connected
        assert not runner.socket_open
        assert runner.next_connect == clock.now + app.INITIAL_RECONNECT_DELAY

        clock.now = runner.next_connect
        runner.step()
        assert len(client.connect_properties) == 2
        assert runner.socket_open

    def test_publishes_only_while_connected(self):
        config = SimulatorConfig(**PLAIN)
        runner, client, state, clock = _runner(config)
        client.fail_connect = True
        runner.step()
        assert client.published == []

        client.fail_connect = False
        _accept_connection(client)
        clock.now = runner.next_connect
        runner.step()
        assert [topic for topic, _ in client.published] == [config.topic_for(m) for m in config.modalities]
        assert state.counters.publish_enqueued == len(config.modalities)

    def test_stop_disconnects_open_socket(self):
        runner, client, _, _ = _runner(SimulatorConfig(**PLAIN))
        _accept_connection(client)
        runner.step()
        runner.stop()
        runner.run()
        assert client.disconnects == 1


@pytest.mark.usefixtures("fake_client")
class TestCallbacks:
    def test_on_control_updates_state_and_counters(self):
        config = SimulatorConfig(**PLAIN, control_enabled=True)
        state = SimulatorState(inject_anomaly=False)
        client = build_client(config, state)
        on_control = client.message_callbacks[config.control_topic]

        on_control(client, None, SimpleNamespace(payload=b'{"inject_anomaly": true}'))
        assert state.inject_anomaly is True
        assert state.counters.control_applied == 1

        on_control(client, None, SimpleNamespace(payload=b'{"inject_anomaly": "false"}'))
        assert state.inject_anomaly is True
        assert state.counters.control_rejected == 1

    def test_connect_subscribes_to_control_topic_only_when_enabled(self):
        enabled = SimulatorConfig(**PLAIN, control_enabled=True)
        client = build_client(enabled, SimulatorState(inject_anomaly=False))
        client.on_connect(client, None, {}, _connack(), None)
        assert client.subscriptions == [(enabled.control_topic, 1)]

        disabled = build_client(SimulatorConfig(**PLAIN), SimulatorState(inject_anomaly=False))
        disabled.on_connect(disabled, None, {}, _connack(), None)
        assert disabled.subscriptions == []
        assert disabled.message_callbacks == {}

    def test_rejected_connection_is_not_counted(self):
        state = SimulatorState(inject_anomaly=False)
        client = build_client(SimulatorConfig(**PLAIN), state)
        client.on_connect(client, None, {}, _connack("Not authorized"), None)
        assert not state.connected
        assert state.counters.connects == 0

    def test_on_publish_counts_acknowledgements_and_rejections(self, caplog):
        state = SimulatorState(inject_anomaly=False)
        client = build_client(SimulatorConfig(**PLAIN), state)
        client.on_publish(client, None, 1, ReasonCode(PacketTypes.PUBACK, "Success"), None)
        with caplog.at_level(logging.WARNING, logger="sensor-simulator"):
            client.on_publish(client, None, 2, ReasonCode(PacketTypes.PUBACK, "Not authorized"), None)
        assert state.counters.publish_acked == 1
        assert state.counters.publish_rejected == 1
        assert caplog.messages == ["Broker rejected publish: Not authorized"]

    def test_on_subscribe_warns_on_rejected_reason_codes(self, caplog):
        client = build_client(SimulatorConfig(**PLAIN, control_enabled=True), SimulatorState(inject_anomaly=False))
        granted = ReasonCode(PacketTypes.SUBACK, "Granted QoS 1")
        denied = ReasonCode(PacketTypes.SUBACK, "Not authorized")
        with caplog.at_level(logging.WARNING, logger="sensor-simulator"):
            client.on_subscribe(client, None, 1, [granted], None)
            assert caplog.messages == []
            client.on_subscribe(client, None, 2, [denied], None)
        assert caplog.messages == ["Broker rejected control subscription: Not authorized"]

    def test_empty_ca_file_uses_system_trust_store(self):
        client = build_client(SimulatorConfig(ca_file=None), SimulatorState(inject_anomaly=False))
        assert client.tls_ca_certs is None

    def test_plain_mqtt_skips_tls(self):
        client = build_client(SimulatorConfig(**PLAIN), SimulatorState(inject_anomaly=False))
        assert client.tls_ca_certs == "unset"


class TestExitCodes:
    def test_missing_ca_file_exits_with_code_2(self, tmp_path, caplog):
        config = SimulatorConfig(ca_file=str(tmp_path / "missing.crt"))
        with caplog.at_level(logging.ERROR, logger="sensor-simulator"):
            assert app.run(config) == 2
        assert "Invalid TLS configuration" in caplog.text

    def test_invalid_ca_file_exits_with_code_2(self, tmp_path):
        bundle = tmp_path / "ca.crt"
        bundle.write_text("-----BEGIN CERTIFICATE-----\nnot a certificate\n-----END CERTIFICATE-----\n")
        assert app.run(SimulatorConfig(ca_file=str(bundle))) == 2

    def test_invalid_environment_exits_with_code_2_without_echoing_values(self, monkeypatch, caplog):
        monkeypatch.setenv("ASSET_ID", "Secret Site")
        monkeypatch.setenv("ACOUSTIC_SAMPLE_COUNT", "777")
        with caplog.at_level(logging.ERROR, logger="sensor-simulator"):
            assert app.main() == 2
        assert "ACOUSTIC_SAMPLE_COUNT" in caplog.text
        assert "Secret Site" not in caplog.text
        assert "777" not in caplog.text
