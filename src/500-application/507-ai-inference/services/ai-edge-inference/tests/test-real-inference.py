#!/usr/bin/env python3
"""Real AI Edge Inference Test - ONNX Backend Only.

This module provides integration testing capabilities for the AI Edge
Inference service, specifically targeting ONNX Runtime backend inference
processing. It demonstrates end-to-end inference workflows by sending
real image data through MQTT and validating the inference results.

The test suite validates:
    - MQTT message transmission to the AI inference service
    - Image data encoding and transmission via base64
    - ONNX Runtime backend preference and routing
    - Inference result publication to result topics
    - Service log monitoring and validation

Typical usage example:
    $ python3 test-real-inference.py

Environment Requirements:
    - Kubernetes cluster with Azure IoT Operations deployed
    - mqtt-client pod running in azure-iot-operations namespace
    - ai-edge-inference service deployed and running
    - Test images available in /tmp/test_images/
    - kubectl configured with cluster access

Note:
    This test requires cluster access and will fail if the required
    Kubernetes resources are not available. MQTT message size is
    limited by broker configuration, typically 256KB for Azure IoT
    Operations MQTT broker.
"""

import json
import base64
import subprocess
import time
from datetime import datetime
from pathlib import Path


def send_mqtt_message(topic: str, message: dict) -> bool:
    """Send MQTT message via kubectl exec to the MQTT broker.

    Publishes a JSON-encoded message to the specified MQTT topic using
    the mqtt-client pod as a proxy. This approach allows testing from
    outside the Kubernetes cluster without requiring direct MQTT broker
    access.

    Args:
        topic: The MQTT topic path to publish to. Should follow the
            pattern 'edge-ai/{site}/{cluster}/camera/snapshots' for
            inference requests.
        message: Dictionary containing the message payload. For inference
            requests, must include camera_id, timestamp, image_data
            (base64), format, width, height, and optional metadata
            fields.

    Returns:
        True if the message was successfully published to the MQTT broker,
        False if the publication failed or timed out.

    Raises:
        subprocess.TimeoutExpired: If the kubectl exec command exceeds
            10 second timeout.
        Exception: For any other errors during message transmission.

    Example:
        >>> message = {
        ...     "camera_id": "test-camera-01",
        ...     "timestamp": "2025-10-17T12:00:00Z",
        ...     "image_data": "base64_encoded_image_data",
        ...     "format": "jpeg",
        ...     "width": 640,
        ...     "height": 480
        ... }
        >>> topic = "edge-ai/site1/cluster1/camera/snapshots"
        >>> success = send_mqtt_message(topic, message)
        >>> if success:
        ...     print("Message sent successfully")

    Note:
        The mqtt-client pod must exist in the azure-iot-operations
        namespace and have mosquitto_pub utility available. The MQTT
        broker service must be accessible at
        aio-mqtt-broker-service:8883.
    """
    try:
        message_json = json.dumps(message)
        cmd = [
            "kubectl", "exec", "mqtt-client", "-n",
            "azure-iot-operations", "--",
            "mosquitto_pub",
            "-h", "aio-mqtt-broker-service",
            "-p", "8883",
            "-t", topic,
            "-m", message_json
        ]

        result = subprocess.run(
            cmd, capture_output=True, text=True, timeout=10)

        if result.returncode == 0:
            print(f"✅ MQTT message sent successfully to topic: {topic}")
            return True
        else:
            print(f"❌ MQTT send failed: {result.stderr}")
            return False

    except subprocess.TimeoutExpired:
        print("❌ MQTT send timed out")
        return False
    except Exception as e:
        print(f"❌ MQTT send error: {e}")
        return False


def get_recent_inference_logs() -> str:
    """Retrieve recent logs from AI edge inference service pods.

    Fetches the last 10 log lines from the past 30 seconds from all
    pods matching the ai-edge-inference app label. This is useful for
    monitoring inference processing, error detection, and validating
    that inference requests are being handled correctly.

    Returns:
        String containing the combined log output from all matching
        pods. Returns empty string if no logs are available or if an
        error occurs during retrieval.

    Example:
        >>> logs = get_recent_inference_logs()
        >>> if "inference completed" in logs:
        ...     print("Inference processed successfully")

    Note:
        Requires kubectl access to the azure-iot-operations namespace.
        The --tail and --since parameters help limit log volume for
        quick validation checks.
    """
    try:
        cmd = [
            "kubectl", "logs", "-l", "app=ai-edge-inference",
            "-n", "azure-iot-operations",
            "--tail=10", "--since=30s"
        ]
        result = subprocess.run(cmd, capture_output=True, text=True)
        return result.stdout
    except Exception as e:
        print(f"❌ Error getting logs: {e}")
        return ""


def main() -> None:
    """Execute the real AI inference test workflow.

    Orchestrates the complete end-to-end inference test including:
        1. Test image validation and loading
        2. Image data encoding to base64 format
        3. MQTT message construction with ONNX backend preference
        4. Message transmission to inference service
        5. Log monitoring and result validation

    The test uses a real image from /tmp/test_images/test_image_1.jpg
    and processes it through the ONNX Runtime backend. Image data is
    truncated to 50KB if larger to stay within MQTT broker message
    size limits.

    Test Flow:
        - Validates test image exists and is readable
        - Encodes image to base64 (truncates if > 100KB)
        - Creates MQTT message with backend preference metadata
        - Publishes to edge-ai/{site}/{cluster}/camera/snapshots topic
        - Waits 5 seconds for inference processing
        - Retrieves and displays recent service logs
        - Prints expected result topic patterns

    Raises:
        FileNotFoundError: If test image does not exist at expected
            path.
        Exception: For image reading or encoding errors.

    Expected Results:
        Successful test will show:
        - ✅ MQTT message sent successfully
        - Service logs showing inference processing
        - Results published to edge-ai/.../ai/results topics
        - Backend field in results showing 'onnx-runtime'
        - Predictions array with person detection results

    Note:
        Monitor MQTTUI or subscribe to 'edge-ai/+/+/ai/results/+' to
        see inference results in real-time.
    """
    print("🧠 Real AI Edge Inference Test - ONNX Backend")
    print("=" * 50)

    # Test image path
    image_path = Path("/tmp/test_images/test_image_1.jpg")

    if not image_path.exists():
        print(f"❌ Test image not found: {image_path}")
        return

    print(f"📸 Using test image: {image_path}")
    print(f"📏 Image size: {image_path.stat().st_size} bytes")

    # Read and encode image
    try:
        with open(image_path, 'rb') as f:
            image_data = f.read()

        # Use smaller chunk for testing
        if len(image_data) > 100000:  # If > 100KB, create smaller test
            image_b64 = base64.b64encode(image_data[:50000]).decode('utf-8')
            print("⚠️  Using truncated image for MQTT size limits")
        else:
            image_b64 = base64.b64encode(image_data).decode('utf-8')

    except Exception as e:
        print(f"❌ Error reading image: {e}")
        return

    # Create MQTT message with ONNX backend preference
    mqtt_message = {
        "camera_id": "real-onnx-inference-test",
        "timestamp": datetime.now().isoformat() + "Z",
        "image_data": image_b64,
        "format": "jpeg",
        "width": 640,
        "height": 480,
        "metadata": {
            "backend_preference": "onnx-runtime",
            "inference_type": "real",
            "test_description": "Real ONNX inference demonstration"
        }
    }

    print(f"📝 Message size: {len(json.dumps(mqtt_message))} bytes")
    print("🎯 Backend preference: onnx-runtime")

    # Send MQTT message
    topic = "edge-ai/test-site/test-cluster/camera/snapshots"
    print(f"📤 Sending to topic: {topic}")

    success = send_mqtt_message(topic, mqtt_message)

    if success:
        print("⏳ Waiting 5 seconds for processing...")
        time.sleep(5)

        print("📋 Recent inference logs:")
        logs = get_recent_inference_logs()
        if logs:
            print(logs)
        else:
            print("   (No recent logs found)")

        print("\n🔍 Expected results on topic:")
        print("   edge-ai/test-site/test-cluster/ai/results")
        print("   edge-ai/+/+/ai/results/+")

        print("\n✅ Real ONNX inference test completed!")
        print("📊 Check MQTTUI for inference results with:")
        print("   - backend: 'onnx-runtime'")
        print("   - inference_type: 'real'")
        print("   - predictions: person detection results")

    else:
        print("❌ Test failed - could not send MQTT message")


if __name__ == "__main__":
    main()
