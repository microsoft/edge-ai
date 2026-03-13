#!/usr/bin/env bash

##
## Discovers PTZ profile token for an ONVIF camera
##
## This script queries the camera's GetProfiles endpoint and extracts
## the profile token(s) that can be used for PTZ commands.
##
## Examples:
##  CAMERA_IP=192.168.1.100 CAMERA_USERNAME=admin CAMERA_PASSWORD="your_password" ./discover-ptz-profile.sh
##
###

set -e

# Configuration
CAMERA_IP="${CAMERA_IP:-}"
CAMERA_PORT="${CAMERA_PORT:-80}"
CAMERA_USERNAME="${CAMERA_USERNAME:-}"
CAMERA_PASSWORD="${CAMERA_PASSWORD:-}"

# Check required parameters
if [[ -z "$CAMERA_IP" ]] || [[ -z "$CAMERA_USERNAME" ]] || [[ -z "$CAMERA_PASSWORD" ]]; then
  echo "❌ Required environment variables missing"
  echo ""
  echo "Usage:"
  echo "  CAMERA_IP=192.168.1.100 CAMERA_USERNAME=admin CAMERA_PASSWORD='your_password' ./discover-ptz-profile.sh"
  echo ""
  echo "Required environment variables:"
  echo "  CAMERA_IP - Camera IP address (e.g., 192.168.1.100)"
  echo "  CAMERA_USERNAME - Camera username (e.g., admin)"
  echo "  CAMERA_PASSWORD - Camera password"
  echo ""
  echo "Optional environment variables:"
  echo "  CAMERA_PORT (default: 80)"
  exit 1
fi

CAMERA_URL="http://${CAMERA_IP}:${CAMERA_PORT}/onvif/device_service"

echo "=========================================="
echo "ONVIF PTZ Profile Discovery Tool"
echo "=========================================="
echo ""
echo "Camera: ${CAMERA_IP}:${CAMERA_PORT}"
echo "User: ${CAMERA_USERNAME}"
echo ""

echo "📡 Querying camera for media profiles..."
echo ""

# Query GetProfiles
response=$(curl --digest -s -X POST "${CAMERA_URL}" \
  -u "${CAMERA_USERNAME}:${CAMERA_PASSWORD}" \
  -H "Content-Type: application/soap+xml" \
  -d '<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope">
  <s:Body>
    <GetProfiles xmlns="http://www.onvif.org/ver10/media/wsdl"/>
  </s:Body>
</s:Envelope>')

# Save raw response
echo "$response" > /tmp/onvif-profiles-response.xml
echo "✅ Raw response saved to: /tmp/onvif-profiles-response.xml"
echo ""

# Check for SOAP fault
if echo "$response" | grep -q "SOAP-ENV:Fault"; then
  echo "❌ Camera returned an error:"
  echo "$response" | grep -A 5 "SOAP-ENV:Text" || echo "$response"
  exit 1
fi

# Try to extract profile tokens (multiple patterns for different cameras)
echo "🔍 Extracting profile tokens..."
echo ""

# Pattern 1: token attribute
tokens=$(echo "$response" | grep -oP 'token="[^"]*"' | cut -d'"' -f2)

# Pattern 2: Profile name or token in elements
if [[ -z "$tokens" ]]; then
  tokens=$(echo "$response" | grep -oP '<[^>]*token>[^<]*' | sed 's/<[^>]*>//')
fi

# Pattern 3: ProfileToken element
if [[ -z "$tokens" ]]; then
  tokens=$(echo "$response" | grep -oP '<ProfileToken>[^<]*' | sed 's/<ProfileToken>//')
fi

if [[ -n "$tokens" ]]; then
  echo "✅ Found profile token(s):"
  echo ""
  while IFS= read -r token; do
    if [[ -n "$token" ]]; then
      echo "  🎯 ProfileToken: $token"
    fi
  done <<< "$tokens"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Next Steps:"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "1. Copy one of the profile tokens above"
  echo "2. Update test-camera-ptz.sh with the correct token"
  echo "3. Run the PTZ test script"
  echo ""
  echo "Example test command:"
  first_token=$(echo "$tokens" | head -n 1 | xargs)
  if [[ -n "$first_token" ]]; then
    echo ""
    echo "  curl --digest -s -X POST \"${CAMERA_URL}\" \\"
    echo "    -u \"${CAMERA_USERNAME}:${CAMERA_PASSWORD}\" \\"
    echo "    -H \"Content-Type: application/soap+xml\" \\"
    echo "    -d '<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
    echo "<s:Envelope xmlns:s=\"http://www.w3.org/2003/05/soap-envelope\" "
    echo "            xmlns:ptz=\"http://www.onvif.org/ver20/ptz/wsdl\">"
    echo "  <s:Body>"
    echo "    <ptz:ContinuousMove>"
    echo "      <ProfileToken>${first_token}</ProfileToken>"
    echo "      <Velocity>"
    echo "        <PanTilt x=\"0.5\" y=\"0.0\" xmlns=\"http://www.onvif.org/ver10/schema\"/>"
    echo "      </Velocity>"
    echo "    </ptz:ContinuousMove>"
    echo "  </s:Body>"
    echo "</s:Envelope>'"
    echo ""
  fi
else
  echo "⚠️  Could not extract profile tokens automatically"
  echo ""
  echo "Please check /tmp/onvif-profiles-response.xml manually"
  echo ""
  echo "Look for patterns like:"
  echo "  - token=\"...\" attribute"
  echo "  - <ProfileToken>...</ProfileToken> element"
  echo "  - <Profile ...> elements with PTZ configuration"
  echo ""
  echo "Common search commands:"
  echo "  cat /tmp/onvif-profiles-response.xml | grep -i profile"
  echo "  cat /tmp/onvif-profiles-response.xml | grep -i token"
  echo "  cat /tmp/onvif-profiles-response.xml | grep -i ptz"
  echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
