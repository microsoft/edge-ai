#!/usr/bin/env python3
"""
Mock Authenticated Device REST API
Simulates a device that requires Basic HTTP authentication
Returns device status and operational data
"""

import os
import random
import time
from datetime import datetime, timezone, timedelta
from flask import Flask, jsonify, request
from functools import wraps

app = Flask(__name__)

# Configuration from environment variables
PORT = int(os.environ.get('PORT', 8082))
DEVICE_ID = os.environ.get('DEVICE_ID', 'auth-device-001')
API_USERNAME = os.environ.get('API_USERNAME', 'deviceuser')
API_PASSWORD = os.environ.get('API_PASSWORD', 'devicepass123')


def check_auth(username, password):
    """Check if a username/password combination is valid.
    
    Args:
        username (str): The username to validate
        password (str): The password to validate
    
    Returns:
        bool: True if credentials match configured values, False otherwise
    """
    return username == API_USERNAME and password == API_PASSWORD


def authenticate():
    """Send a 401 Unauthorized response that enables HTTP Basic authentication.
    
    Returns:
        tuple: A Flask response tuple containing:
            - JSON error message
            - 401 status code
            - WWW-Authenticate header for Basic auth
    """
    return jsonify({
        'error': 'Authentication required',
        'message': 'Please provide valid credentials'
    }), 401, {'WWW-Authenticate': 'Basic realm="Device API"'}


def requires_auth(f):
    """Decorator that enforces HTTP Basic authentication for endpoints.
    
    This decorator checks the Authorization header for valid Basic auth credentials.
    If credentials are missing or invalid, it returns a 401 response.
    
    Args:
        f (function): The Flask route function to decorate
    
    Returns:
        function: Decorated function with authentication enforcement
    """
    @wraps(f)
    def decorated(*args, **kwargs):
        auth = request.authorization
        if not auth or not check_auth(auth.username, auth.password):
            return authenticate()
        return f(*args, **kwargs)
    return decorated


def generate_device_status():
    """Generate realistic simulated device status data.
    
    Creates a comprehensive device status payload with randomized values
    for operational state, health metrics, CPU/memory/disk usage,
    network status, and configuration information.
    
    Returns:
        dict: Device status information including:
            - timestamp: Current UTC timestamp
            - device_id: Device identifier
            - device_type: Type of device (authenticated_controller)
            - status: Operational metrics (CPU, memory, disk, network, temperature)
            - metrics: Uptime and operation counters
            - configuration: Firmware version and security settings
    """
    return {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "device_id": DEVICE_ID,
        "device_type": "authenticated_controller",
        "status": {
            "operational_state": random.choice(["running", "standby", "maintenance"]),
            "health": random.choice(["healthy", "warning", "normal"]),
            "cpu_usage": round(random.uniform(5.0, 45.0), 2),
            "memory_usage": round(random.uniform(30.0, 70.0), 2),
            "disk_usage": round(random.uniform(15.0, 85.0), 2),
            "network_status": random.choice(["connected", "connected", "slow", "unstable"]),
            "temperature": round(random.uniform(35.0, 65.0), 2)
        },
        "metrics": {
            # 1 hour to 30 days
            "uptime_seconds": random.randint(3600, 2592000),
            "total_requests": random.randint(1000, 50000),
            "successful_operations": random.randint(950, 49500),
            "failed_operations": random.randint(0, 50),
            "last_maintenance": "2025-09-15T08:00:00Z"
        },
        "configuration": {
            "firmware_version": "3.2.1",
            "config_version": "1.4.2",
            "security_level": "high",
            "auth_enabled": True,
            "logging_level": "info"
        }
    }


@app.route('/health', methods=['GET'])
@requires_auth
def health_check():
    """Health check endpoint for monitoring service availability.
    
    Requires HTTP Basic authentication. Returns minimal health status
    information to verify the service is running and accessible.
    
    Returns:
        Response: JSON containing status, timestamp, device_id,
                  authenticated flag, and uptime
    """
    return jsonify({
        "status": "healthy",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "device_id": DEVICE_ID,
        "authenticated": True,
        "uptime": time.time()
    })


@app.route('/api/device/status', methods=['GET'])
@requires_auth
def get_device_status():
    """Get comprehensive current device status and operational metrics.
    
    Requires HTTP Basic authentication. Returns detailed information about
    the device's current operational state, health metrics, performance
    statistics, and configuration.
    
    Returns:
        Response: JSON containing complete device status including operational
                  state, health metrics, uptime, request counters, and config
    """
    return jsonify(generate_device_status())


@app.route('/api/device/config', methods=['GET'])
@requires_auth
def get_device_config():
    """Get complete device configuration and installation details.
    
    Requires HTTP Basic authentication. Returns static configuration
    information including device metadata, network settings, security
    configuration, physical location, and supported capabilities.
    
    Returns:
        Response: JSON containing device configuration including manufacturer
                  info, network settings, security config, and capabilities
    """
    return jsonify({
        "device_id": DEVICE_ID,
        "device_name": "Secure Industrial Controller",
        "manufacturer": "SecureDevices Corp",
        "model": "SDC-IC-2024",
        "serial_number": os.environ.get('SERIAL_NUMBER', f"SDC{random.randint(100000, 999999)}"),
        "installation_date": "2025-08-01T00:00:00Z",
        "location": {
            "facility": "Building A",
            "floor": "Level 2",
            "room": "Control Room 201"
        },
        "network": {
            "ip_address": "192.168.1.100",
            "mac_address": "00:1B:44:11:3A:B7",
            "subnet": "255.255.255.0",
            "gateway": "192.168.1.1"
        },
        "security": {
            "auth_method": "basic_http",
            "encryption": "TLS 1.3",
            "certificate_expiry": "2026-08-01T00:00:00Z",
            "password_policy": "strong",
            "session_timeout": 3600
        },
        "capabilities": [
            "status_monitoring",
            "configuration_management",
            "remote_control",
            "data_logging",
            "alert_generation"
        ]
    })


@app.route('/api/device/logs', methods=['GET'])
@requires_auth
def get_device_logs():
    """Get recent device operational logs.
    
    Requires HTTP Basic authentication. Returns the most recent log entries
    with varying log levels (INFO, WARN, ERROR, DEBUG) and component sources.
    
    Returns:
        Response: JSON containing log entries array with timestamp, level,
                  message, and component for the last 10 log entries
    """
    # Generate some mock log entries
    logs = []
    base_time = datetime.now(timezone.utc)

    log_levels = ["INFO", "WARN", "ERROR", "DEBUG"]
    log_messages = [
        "System startup completed successfully",
        "Configuration updated",
        "Network connection established",
        "Sensor reading collected",
        "Maintenance mode activated",
        "Authentication attempt logged",
        "Performance metrics updated",
        "Backup operation completed"
    ]

    for i in range(10):
        timestamp = base_time - timedelta(minutes=i)
        logs.append({
            "timestamp": timestamp.isoformat(),
            "level": random.choice(log_levels),
            "message": random.choice(log_messages),
            "component": random.choice(["auth", "network", "sensor", "system", "config"])
        })

    return jsonify({
        "device_id": DEVICE_ID,
        "log_count": len(logs),
        "period": "last_10_entries",
        "logs": logs
    })


@app.route('/api/auth/test', methods=['GET'])
@requires_auth
def test_auth():
    """Test endpoint for verifying HTTP Basic authentication.
    
    Requires HTTP Basic authentication. Useful for testing credentials
    and verifying that authentication is working correctly.
    
    Returns:
        Response: JSON confirming successful authentication with timestamp,
                  device_id, authenticated username, and auth method
    """
    return jsonify({
        "message": "Authentication successful",
        "device_id": DEVICE_ID,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "authenticated_user": API_USERNAME,
        "auth_method": "basic_http"
    })


@app.route('/', methods=['GET'])
def root():
    """Root endpoint providing API discovery and documentation.
    
    This endpoint does not require authentication, allowing clients to
    discover available endpoints, authentication requirements, and test
    credentials for development purposes.
    
    Returns:
        Response: JSON containing service information, available endpoints,
                  authentication requirements, and test credentials
    """
    return jsonify({
        "service": "Mock Authenticated Device API",
        "device_id": DEVICE_ID,
        "version": "1.0.0",
        "authentication": "basic_http_required",
        "test_credentials": f"{API_USERNAME}:{API_PASSWORD}",
        "endpoints": [
            "/health (AUTH REQUIRED)",
            "/api/device/status (AUTH REQUIRED)",
            "/api/device/config (AUTH REQUIRED)",
            "/api/device/logs (AUTH REQUIRED)",
            "/api/auth/test (AUTH REQUIRED)"
        ],
        "authentication_note": "All endpoints except root require Basic HTTP authentication",
        "documentation": "https://github.com/microsoft/edge-ai/tree/main/src/500-application/505-akri-rest-http-connector"
    })


if __name__ == '__main__':
    print(f"Starting Mock Authenticated Device API for {DEVICE_ID}")
    print(f"Authentication: {API_USERNAME}:{API_PASSWORD}")
    print(f"Server running on port {PORT}")
    app.run(host='0.0.0.0', port=PORT, debug=False)
