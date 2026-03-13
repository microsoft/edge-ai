# Testing ONVIF Cameras - Generic Scripts

This directory contains generic scripts for testing ONVIF camera connectivity and PTZ functionality.

## Prerequisites

Before using these scripts:

1. ✅ **ONVIF service enabled** on your camera
2. ✅ Camera accessible on your network
3. ✅ Valid credentials (username and password)
4. ✅ `curl` installed on your system
5. ✅ `kubectl` access (optional, for Kubernetes secret integration)

## Script Overview

### 1. discover-ptz-profile.sh

Discovers PTZ profile tokens from your ONVIF camera.

**Usage:**

```bash
CAMERA_IP=192.168.1.100 \
CAMERA_USERNAME=admin \
CAMERA_PASSWORD='your_password' \
./discover-ptz-profile.sh
```

**Parameters:**

| Variable          | Required | Default | Description        |
|-------------------|----------|---------|--------------------|
| `CAMERA_IP`       | ✅ Yes    | none    | Camera IP address  |
| `CAMERA_USERNAME` | ✅ Yes    | none    | Camera username    |
| `CAMERA_PASSWORD` | ✅ Yes    | none    | Camera password    |
| `CAMERA_PORT`     | No       | 80      | ONVIF service port |

**Expected Output:**

```
✅ Found profile token(s):
  🎯 ProfileToken: MainStream
  🎯 ProfileToken: SubStream
```

### 2. quick-ptz-test.sh

Performs quick PTZ movement tests (pan left/right, tilt up/down).

**Usage:**

```bash
CAMERA_IP=192.168.1.100 \
CAMERA_USERNAME=admin \
CAMERA_PASSWORD='your_password' \
PROFILE_TOKEN=MainStream \
./quick-ptz-test.sh
```

**Alternative - Load from Kubernetes Secret:**

```bash
CAMERA_IP=192.168.1.100 \
K8S_SECRET_NAME=camera-01-credentials \
PROFILE_TOKEN=MainStream \
./quick-ptz-test.sh
```

**Parameters:**

| Variable          | Required | Default              | Description                      |
|-------------------|----------|----------------------|----------------------------------|
| `CAMERA_IP`       | ✅ Yes    | none                 | Camera IP address                |
| `CAMERA_USERNAME` | ✅ Yes*   | none                 | Camera username                  |
| `CAMERA_PASSWORD` | ✅ Yes*   | none                 | Camera password                  |
| `PROFILE_TOKEN`   | No       | MainStream           | PTZ profile token                |
| `CAMERA_PORT`     | No       | 80                   | ONVIF service port               |
| `K8S_SECRET_NAME` | No       | none                 | Load credentials from K8s secret |
| `K8S_NAMESPACE`   | No       | azure-iot-operations | Kubernetes namespace             |

\* Required unless using `K8S_SECRET_NAME`

**Expected Behavior:**

Camera should physically move during each test:

- Test 1: Pan right for 2 seconds
- Test 2: Pan left for 2 seconds  
- Test 3: Tilt up for 2 seconds
- Test 4: Tilt down for 2 seconds

## Common Issues

### Issue: "Data required for operation"

**Cause**: ONVIF service is disabled on camera.

**Solution**:

1. Access camera web interface
2. Navigate to Settings → Network → Advanced → ONVIF
3. Enable ONVIF service
4. Set authentication to Digest
5. Save and reboot camera

### Issue: "Connection refused"

**Cause**: Wrong port or service not running.

**Solution**:

- Try different ports: `CAMERA_PORT=8000` or `CAMERA_PORT=8080`
- Verify ONVIF is enabled in camera settings

### Issue: "Invalid username or password"

**Cause**: Wrong credentials or authentication method.

**Solution**:

1. Verify credentials by logging into camera web interface
2. Check if ONVIF user permissions are enabled
3. Ensure user has Administrator or ONVIF access role

### Issue: Camera doesn't move during PTZ test

**Possible Causes**:

1. Wrong profile token - use `discover-ptz-profile.sh` to find correct token
2. Camera doesn't support PTZ
3. PTZ locked in camera settings or manual mode
4. Commands succeed but camera at movement limit (end of pan/tilt range)

**Solution**:

1. Run `discover-ptz-profile.sh` to get correct profile token
2. Check camera specifications for PTZ support
3. Disable manual mode or auto-tracking features
4. Try different movement directions

## Step-by-Step Testing Guide

### Step 1: Enable ONVIF on Camera

1. Access camera web interface: `http://YOUR-CAMERA-IP`
2. Login with admin credentials
3. Navigate to ONVIF settings (usually under Network → Advanced)
4. Enable ONVIF service
5. Set Authentication to Digest
6. Save and reboot camera
7. Wait 60 seconds for full startup

### Step 2: Test Basic ONVIF Connectivity

```bash
curl -X POST http://YOUR-CAMERA-IP/onvif/device_service \
  -H "Content-Type: application/soap+xml" \
  --max-time 10 \
  -d '<?xml version="1.0" encoding="UTF-8"?><s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope"><s:Body><GetSystemDateAndTime xmlns="http://www.onvif.org/ver10/device/wsdl"/></s:Body></s:Envelope>'
```

**Expected**: XML response with date/time  
**Error**: "Data required for operation" → ONVIF not enabled

### Step 3: Discover PTZ Profile Token

```bash
CAMERA_IP=YOUR-CAMERA-IP \
CAMERA_USERNAME=admin \
CAMERA_PASSWORD='your_password' \
./discover-ptz-profile.sh
```

Note the profile token(s) displayed (usually `MainStream` or `token0`).

### Step 4: Test PTZ Movement

```bash
CAMERA_IP=YOUR-CAMERA-IP \
CAMERA_USERNAME=admin \
CAMERA_PASSWORD='your_password' \
PROFILE_TOKEN=MainStream \
./quick-ptz-test.sh
```

Watch your camera - it should physically move during each test.

### Step 5: Verify Success

✅ Camera responds to ONVIF queries  
✅ Profile token(s) discovered  
✅ Camera moves during PTZ tests  
✅ No authentication errors

## Camera-Specific Notes

### Reolink Cameras

- Default port: 80
- Path: `/onvif/device_service`
- **ONVIF disabled by default** - must enable in settings
- Reboot required after enabling ONVIF
- Profile token usually: `MainStream`

### Amcrest Cameras

- Default port: 80
- Path: `/onvif/device_service`
- ONVIF usually enabled by default
- Default credentials: `admin` / `admin`
- Profile token usually: `MainStream`

### Hikvision Cameras

- Default port: 80
- Path: `/onvif/device_service`
- May require "Platform Access" enabled
- Profile token varies by model

### Dahua Cameras

- Default port: 80
- Path: `/onvif/device_service`
- Check Settings > Network > Port for ONVIF
- Profile token varies by model

## Integration with Azure IoT Operations

After successful testing, your camera is ready for Azure IoT Operations deployment.

See:

- [ONVIF-CAMERA-QUICKSTART.md](../ONVIF-CAMERA-QUICKSTART.md) - Full deployment guide
- [ONVIF-CAMERA-DEPLOYMENT.md](../ONVIF-CAMERA-DEPLOYMENT.md) - Detailed documentation

## Additional Resources

- **ONVIF Specifications**: <https://www.onvif.org/specs/core/ONVIF-Core-Specification.pdf>
- **ONVIF Test Tool**: <https://www.onvif.org/test-tool/>
- **ONVIF Device Manager** (Windows): <https://sourceforge.net/projects/onvifdm/>

---

**Last Updated**: December 19, 2025  
**Tested With**: Various ONVIF Profile S/T cameras
