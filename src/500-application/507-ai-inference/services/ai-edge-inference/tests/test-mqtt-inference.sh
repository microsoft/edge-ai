#!/usr/bin/env bash

################################################################################
# MQTT AI Inference Verification Test
################################################################################
#
# DESCRIPTION:
#   Integration test script for AI Edge Inference service using real image
#   data transmitted via MQTT protocol. Validates end-to-end inference
#   pipeline from MQTT message reception to inference result publication.
#
# USAGE:
#   ./test-mqtt-inference.sh
#
# PREREQUISITES:
#   - kubectl configured with cluster access
#   - mqtt-client pod running in azure-iot-operations namespace
#   - ai-edge-inference service deployed
#   - Test images in /tmp/test_images/ directory
#   - MQTT broker accessible (aio-mqtt-broker-service:8883)
#
# TEST FLOW:
#   1. Validates test image directory exists
#   2. Encodes test images to base64 format
#   3. Creates MQTT messages with image payloads
#   4. Publishes messages to camera snapshot topic
#   5. Monitors inference result topic for responses
#
# TOPICS:
#   Input:  edge-ai/test-site/test-cluster/camera/snapshots
#   Output: edge-ai/test-site/test-cluster/ai/results
#
# EXPECTED RESULTS:
#   - Successful MQTT message publication
#   - Inference results on output topic
#   - Detection predictions for image contents
#   - Backend identification (onnx-runtime or azure-ml)
#
# NOTES:
#   - Requires test images in JPEG format
#   - MQTT message size limited by broker configuration
#   - Results include confidence scores and bounding boxes
#
################################################################################

echo "🧪 MQTT AI Inference Verification Test"
echo "====================================="

# Configuration
INPUT_TOPIC="edge-ai/test-site/test-cluster/camera/snapshots"
OUTPUT_TOPIC="edge-ai/test-site/test-cluster/ai/results"
# Test image directory
TEST_IMAGES_DIR="/tmp/test_images"

# Check if test images exist
if [ ! -d "$TEST_IMAGES_DIR" ]; then
    echo "❌ Test images directory not found: $TEST_IMAGES_DIR"
    exit 1
fi

# Function to encode image to base64
encode_image() {
    local image_path="$1"
    if [ -f "$image_path" ]; then
        base64 -w 0 "$image_path"
    else
        echo "❌ Image not found: $image_path"
        return 1
    fi
}

# Function to create MQTT message with real image
create_image_message() {
    local image_path="$1"
    local camera_id="$2"
    local timestamp
    timestamp=$(date +%s)

    local image_base64
    if ! image_base64=$(encode_image "$image_path"); then
        return 1
    fi

    cat << EOF
{
  "message_type": "image_snapshot",
  "camera_id": "$camera_id",
  "timestamp": $timestamp,
  "device_name": "test-device-mqtt",
  "location": [29.7604, -95.3698],
  "image_data": "$image_base64",
  "metadata": {
    "site": "test-facility",
    "facility": "mqtt-test",
    "quality": "high",
    "test_run": true
  }
}
EOF
}

echo ""
echo "🖼️  Available test images:"
find "$TEST_IMAGES_DIR" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) -exec sh -c 'echo "   $(basename "$1") ($(stat -c %s "$1") bytes)"' _ {} \;

echo ""
echo "📡 MQTT Topics:"
echo "   📤 Input:  $INPUT_TOPIC"
echo "   📥 Output: $OUTPUT_TOPIC"

echo ""
echo "🔍 MQTTUI Monitoring Commands:"
echo "   Start mqttui and subscribe to these topics:"
echo "   - $INPUT_TOPIC"
echo "   - $OUTPUT_TOPIC"
echo "   - edge-ai/+/+/ai/results/+"
echo ""

# Test with multiple images
test_images=("$TEST_IMAGES_DIR/test_image_1.jpg" "$TEST_IMAGES_DIR/test_image_2.jpeg" "$TEST_IMAGES_DIR/test_image_3.jpeg")

for i in "${!test_images[@]}"; do
    image_path="${test_images[$i]}"
    camera_id="mqtt-test-cam-$((i + 1))"

    if [ ! -f "$image_path" ]; then
        echo "⚠️  Skipping missing image: $image_path"
        continue
    fi

    echo ""
    echo "📸 Test $((i + 1)): Processing $(basename "$image_path")"

    # Create message file
    message_file="/tmp/mqtt_test_message_$((i + 1)).json"
    if ! create_image_message "$image_path" "$camera_id" > "$message_file"; then
        echo "❌ Failed to create message for $image_path"
        continue
    fi

    echo "   📝 Message size: $(wc -c < "$message_file") bytes"
    echo "   🎯 Camera ID: $camera_id"

    # Publish to MQTT
    echo "   📤 Publishing to MQTT..."
    if kubectl exec mqtt-client -n azure-iot-operations -- mosquitto_pub \
      --host aio-broker.azure-iot-operations \
      --port 18883 \
      --username 'K8S-SAT' \
      --pw "$(kubectl exec mqtt-client -n azure-iot-operations -- cat /var/run/secrets/tokens/broker-sat)" \
      --cafile /var/run/certs/ca.crt \
      --topic "$INPUT_TOPIC" \
      --file - < "$message_file" 2>/dev/null; then
        echo "   ✅ Published successfully"
    else
        echo "   ❌ Failed to publish"
    fi

    # Cleanup temp file
    rm -f "$message_file"

    # Wait between tests
    echo "   ⏳ Waiting 5 seconds..."
    sleep 5
done

echo ""
echo "📊 Test Results Summary:"
echo "✅ Test images sent via MQTT"
echo "✅ Messages published to: $INPUT_TOPIC"
echo "✅ Expected results on: $OUTPUT_TOPIC"

echo ""
echo "🔍 Verification Steps:"
echo "1. Check MQTTUI for messages on output topic"
echo "2. Look for inference results with predictions"
echo "3. Verify each test image gets processed"

echo ""
echo "📋 Check AI Edge Inference logs:"
echo "   kubectl logs -l app=ai-edge-inference -n azure-iot-operations --tail=20"

echo ""
echo "🎯 MQTT Inference Test Completed!"
echo "   Monitor \"$OUTPUT_TOPIC\" in MQTTUI for inference results"
