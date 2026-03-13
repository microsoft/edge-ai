#!/bin/bash
################################################################################
# Quick PTZ Test for ONVIF Camera
#
# This script performs a quick PTZ test on your ONVIF camera.
# You can provide credentials via environment variables or Kubernetes secret.
#
# Usage:
#   CAMERA_IP=192.168.1.100 CAMERA_USERNAME=admin CAMERA_PASSWORD='pass' ./quick-ptz-test.sh
#   Or set K8S_SECRET_NAME to load from Kubernetes
################################################################################

set -e

# Camera details - all required
CAMERA_IP="${CAMERA_IP:-}"
CAMERA_PORT="${CAMERA_PORT:-80}"
CAMERA_USERNAME="${CAMERA_USERNAME:-}"
CAMERA_PASSWORD="${CAMERA_PASSWORD:-}"
PROFILE_TOKEN="${PROFILE_TOKEN:-MainStream}"
K8S_SECRET_NAME="${K8S_SECRET_NAME:-}"
K8S_NAMESPACE="${K8S_NAMESPACE:-azure-iot-operations}"

# Try to load from Kubernetes secret if specified
if [[ -n "$K8S_SECRET_NAME" ]]; then
  echo "🔑 Loading credentials from Kubernetes secret: ${K8S_SECRET_NAME}..."
  CAMERA_USERNAME=$(kubectl get secret "${K8S_SECRET_NAME}" -n "${K8S_NAMESPACE}" -o jsonpath='{.data.username}' 2>/dev/null | base64 -d || echo "")
  CAMERA_PASSWORD=$(kubectl get secret "${K8S_SECRET_NAME}" -n "${K8S_NAMESPACE}" -o jsonpath='{.data.password}' 2>/dev/null | base64 -d || echo "")
  
  if [[ -n "$CAMERA_USERNAME" ]] && [[ -n "$CAMERA_PASSWORD" ]]; then
    echo "✅ Credentials loaded from secret"
  else
    echo "⚠️  Warning: Could not load credentials from secret"
  fi
fi

# Validate required parameters
if [[ -z "$CAMERA_IP" ]] || [[ -z "$CAMERA_USERNAME" ]] || [[ -z "$CAMERA_PASSWORD" ]]; then
  echo "❌ Required parameters missing"
  echo ""
  echo "Usage:"
  echo "  CAMERA_IP=192.168.1.100 CAMERA_USERNAME=admin CAMERA_PASSWORD='pass' ./quick-ptz-test.sh"
  echo ""
  echo "Or load from Kubernetes secret:"
  echo "  CAMERA_IP=192.168.1.100 K8S_SECRET_NAME=camera-credentials ./quick-ptz-test.sh"
  echo ""
  echo "Required environment variables:"
  echo "  CAMERA_IP - Camera IP address"
  echo "  CAMERA_USERNAME - Camera username"
  echo "  CAMERA_PASSWORD - Camera password"
  echo ""
  echo "Optional environment variables:"
  echo "  CAMERA_PORT - ONVIF port (default: 80)"
  echo "  PROFILE_TOKEN - PTZ profile token (default: MainStream)"
  echo "  K8S_SECRET_NAME - Kubernetes secret name to load credentials from"
  echo "  K8S_NAMESPACE - Kubernetes namespace (default: azure-iot-operations)"
  exit 1
fi

CAMERA_URL="http://${CAMERA_IP}:${CAMERA_PORT}/onvif/device_service"

echo ""
echo "🎥 Testing ONVIF Camera PTZ at ${CAMERA_IP}:${CAMERA_PORT}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 1: Pan Right
echo "📹 Test 1: Panning Right (2 seconds)..."
curl --digest -s -X POST "${CAMERA_URL}" \
  -u "${CAMERA_USERNAME}:${CAMERA_PASSWORD}" \
  -H "Content-Type: application/soap+xml" \
  -d '<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" 
            xmlns:ptz="http://www.onvif.org/ver20/ptz/wsdl">
  <s:Body>
    <ptz:ContinuousMove>
      <ProfileToken>${PROFILE_TOKEN}</ProfileToken>
      <Velocity>
        <PanTilt x="0.5" y="0.0" xmlns="http://www.onvif.org/ver10/schema"/>
      </Velocity>
    </ptz:ContinuousMove>
  </s:Body>
</s:Envelope>' \
  --max-time 5 > /tmp/ptz-response.xml 2>&1

if grep -q "ContinuousMoveResponse\|HTTP" /tmp/ptz-response.xml; then
  echo "   ✅ Command sent successfully"
else
  echo "   ⚠️  Response: $(cat /tmp/ptz-response.xml | grep -o "SOAP-ENV:Text[^<]*" | head -1)"
fi

sleep 2

# Stop
echo "🛑 Stopping movement..."
curl --digest -s -X POST "${CAMERA_URL}" \
  -u "${CAMERA_USERNAME}:${CAMERA_PASSWORD}" \
  -H "Content-Type: application/soap+xml" \
  -d '<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" 
            xmlns:ptz="http://www.onvif.org/ver20/ptz/wsdl">
  <s:Body>
    <ptz:Stop>
      <ProfileToken>${PROFILE_TOKEN}</ProfileToken>
      <PanTilt>true</PanTilt>
      <Zoom>true</Zoom>
    </ptz:Stop>
  </s:Body>
</s:Envelope>' \
  --max-time 5 > /dev/null 2>&1

sleep 1

# Test 2: Pan Left
echo "📹 Test 2: Panning Left (2 seconds)..."
curl --digest -s -X POST "${CAMERA_URL}" \
  -u "${CAMERA_USERNAME}:${CAMERA_PASSWORD}" \
  -H "Content-Type: application/soap+xml" \
  -d '<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" 
            xmlns:ptz="http://www.onvif.org/ver20/ptz/wsdl">
  <s:Body>
    <ptz:ContinuousMove>
      <ProfileToken>${PROFILE_TOKEN}</ProfileToken>
      <Velocity>
        <PanTilt x="-0.5" y="0.0" xmlns="http://www.onvif.org/ver10/schema"/>
      </Velocity>
    </ptz:ContinuousMove>
  </s:Body>
</s:Envelope>' \
  --max-time 5 > /tmp/ptz-response.xml 2>&1

if grep -q "ContinuousMoveResponse\|HTTP" /tmp/ptz-response.xml; then
  echo "   ✅ Command sent successfully"
else
  echo "   ⚠️  Response: $(cat /tmp/ptz-response.xml | grep -o "SOAP-ENV:Text[^<]*" | head -1)"
fi

sleep 2

# Stop
curl --digest -s -X POST "${CAMERA_URL}" \
  -u "${CAMERA_USERNAME}:${CAMERA_PASSWORD}" \
  -H "Content-Type: application/soap+xml" \
  -d '<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" 
            xmlns:ptz="http://www.onvif.org/ver20/ptz/wsdl">
  <s:Body>
    <ptz:Stop>
      <ProfileToken>${PROFILE_TOKEN}</ProfileToken>
      <PanTilt>true</PanTilt>
      <Zoom>true</Zoom>
    </ptz:Stop>
  </s:Body>
</s:Envelope>' \
  --max-time 5 > /dev/null 2>&1

sleep 1

# Test 3: Tilt Up
echo "📹 Test 3: Tilting Up (2 seconds)..."
curl --digest -s -X POST "${CAMERA_URL}" \
  -u "${CAMERA_USERNAME}:${CAMERA_PASSWORD}" \
  -H "Content-Type: application/soap+xml" \
  -d '<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" 
            xmlns:ptz="http://www.onvif.org/ver20/ptz/wsdl">
  <s:Body>
    <ptz:ContinuousMove>
      <ProfileToken>${PROFILE_TOKEN}</ProfileToken>
      <Velocity>
        <PanTilt x="0.0" y="0.5" xmlns="http://www.onvif.org/ver10/schema"/>
      </Velocity>
    </ptz:ContinuousMove>
  </s:Body>
</s:Envelope>' \
  --max-time 5 > /tmp/ptz-response.xml 2>&1

if grep -q "ContinuousMoveResponse\|HTTP" /tmp/ptz-response.xml; then
  echo "   ✅ Command sent successfully"
else
  echo "   ⚠️  Response: $(cat /tmp/ptz-response.xml | grep -o "SOAP-ENV:Text[^<]*" | head -1)"
fi

sleep 2

# Stop
curl --digest -s -X POST "${CAMERA_URL}" \
  -u "${CAMERA_USERNAME}:${CAMERA_PASSWORD}" \
  -H "Content-Type: application/soap+xml" \
  -d '<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" 
            xmlns:ptz="http://www.onvif.org/ver20/ptz/wsdl">
  <s:Body>
    <ptz:Stop>
      <ProfileToken>${PROFILE_TOKEN}</ProfileToken>
      <PanTilt>true</PanTilt>
      <Zoom>true</Zoom>
    </ptz:Stop>
  </s:Body>
</s:Envelope>' \
  --max-time 5 > /dev/null 2>&1

sleep 1

# Test 4: Tilt Down
echo "📹 Test 4: Tilting Down (2 seconds)..."
curl --digest -s -X POST "${CAMERA_URL}" \
  -u "${CAMERA_USERNAME}:${CAMERA_PASSWORD}" \
  -H "Content-Type: application/soap+xml" \
  -d '<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" 
            xmlns:ptz="http://www.onvif.org/ver20/ptz/wsdl">
  <s:Body>
    <ptz:ContinuousMove>
      <ProfileToken>${PROFILE_TOKEN}</ProfileToken>
      <Velocity>
        <PanTilt x="0.0" y="-0.5" xmlns="http://www.onvif.org/ver10/schema"/>
      </Velocity>
    </ptz:ContinuousMove>
  </s:Body>
</s:Envelope>' \
  --max-time 5 > /tmp/ptz-response.xml 2>&1

if grep -q "ContinuousMoveResponse\|HTTP" /tmp/ptz-response.xml; then
  echo "   ✅ Command sent successfully"
else
  echo "   ⚠️  Response: $(cat /tmp/ptz-response.xml | grep -o "SOAP-ENV:Text[^<]*" | head -1)"
fi

sleep 2

# Final Stop
curl --digest -s -X POST "${CAMERA_URL}" \
  -u "${CAMERA_USERNAME}:${CAMERA_PASSWORD}" \
  -H "Content-Type: application/soap+xml" \
  -d '<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" 
            xmlns:ptz="http://www.onvif.org/ver20/ptz/wsdl">
  <s:Body>
    <ptz:Stop>
      <ProfileToken>${PROFILE_TOKEN}</ProfileToken>
      <PanTilt>true</PanTilt>
      <Zoom>true</Zoom>
    </ptz:Stop>
  </s:Body>
</s:Envelope>' \
  --max-time 5 > /dev/null 2>&1

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ PTZ Test Complete!"
echo ""
echo "Did your camera move during the tests?"
echo "  - Pan Right (first test)"
echo "  - Pan Left (second test)"
echo "  - Tilt Up (third test)"
echo "  - Tilt Down (fourth test)"
echo ""
echo "If the camera didn't move, check:"
echo "  1. Camera password is correct in the Kubernetes secret"
echo "  2. Camera PTZ is enabled in camera settings"
echo "  3. Response messages above for errors"
echo ""
