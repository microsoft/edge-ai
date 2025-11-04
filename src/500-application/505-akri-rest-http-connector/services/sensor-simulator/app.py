#!/usr/bin/env python3
"""
Mock Generic Sensor REST API
Simulates a generic sensor that provides temperature and humidity data
Similar to DHT11/DHT22 sensor output
"""

import os
import random
import time
from datetime import datetime, timezone
from flask import Flask, jsonify

app = Flask(__name__)

# Configuration from environment variables
PORT = int(os.environ.get('PORT', 8081))
DEVICE_ID = os.environ.get('DEVICE_ID', 'generic-sensor-001')
SENSOR_TYPE = os.environ.get('SENSOR_TYPE', 'temperature-humidity')


def generate_sensor_data():
    """Generate realistic simulated sensor data.
    
    Simulates DHT11/DHT22 temperature and humidity sensor readings with
    realistic ranges and formats. Temperature ranges from 15-35°C and
    humidity from 20-90%.
    
    Returns:
        dict: Sensor data including:
            - timestamp: Current timestamp in YYYY/MM/DD HH:MM:SS format
            - device_id: Sensor identifier
            - sensor_type: Type of sensor (temperature-humidity)
            - temperature: Values in Celsius and Fahrenheit
            - humidity: Percentage value
            - status: Error codes, health, and reading quality
    """
    # Simulate DHT11/DHT22 sensor ranges
    temperature_c = round(random.uniform(15.0, 35.0), 2)  # 15-35°C
    humidity_pct = round(random.uniform(20.0, 90.0), 2)   # 20-90%

    return {
        "timestamp": datetime.now(timezone.utc).strftime("%Y/%m/%d %H:%M:%S"),
        "device_id": DEVICE_ID,
        "sensor_type": SENSOR_TYPE,
        "temperature": {
            "celsius": temperature_c,
            "fahrenheit": round((temperature_c * 9/5) + 32, 2)
        },
        "humidity": {
            "percent": humidity_pct
        },
        "status": {
            "error_code": 0,
            "error_message": "OK",
            "sensor_health": "normal",
            "reading_quality": random.choice(["good", "excellent", "fair"])
        }
    }


@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint for monitoring service availability.
    
    Lightweight endpoint for health monitoring and service discovery.
    Does not require authentication.
    
    Returns:
        Response: JSON containing status, timestamp, device_id,
                  sensor_type, and uptime
    """
    return jsonify({
        "status": "healthy",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "device_id": DEVICE_ID,
        "sensor_type": SENSOR_TYPE,
        "uptime": time.time()
    })


@app.route('/api/sensor/data', methods=['GET'])
def get_sensor_data():
    """Get current sensor reading.
    
    Returns real-time temperature and humidity measurements from the
    simulated sensor, along with status information and reading quality.
    
    Returns:
        Response: JSON containing current sensor measurements, status,
                  and quality indicators
    """
    return jsonify(generate_sensor_data())


@app.route('/api/sensor/status', methods=['GET'])
def get_sensor_status():
    """Get comprehensive sensor status and operational information.
    
    Returns detailed information about the sensor's operational state,
    including total readings, error counts, calibration dates, firmware
    version, and hardware revision.
    
    Returns:
        Response: JSON containing sensor status, statistics, calibration
                  info, and hardware details
    """
    return jsonify({
        "device_id": DEVICE_ID,
        "sensor_type": SENSOR_TYPE,
        "status": "online",
        "last_reading": datetime.now(timezone.utc).isoformat(),
        "total_readings": random.randint(1000, 10000),
        "error_count": random.randint(0, 5),
        "calibration_date": "2025-09-01T12:00:00Z",
        "next_calibration": "2026-03-01T12:00:00Z",
        "firmware_version": "2.1.4",
        "hardware_revision": "Rev C"
    })


@app.route('/api/device/info', methods=['GET'])
def get_device_info():
    """Get comprehensive sensor device information.
    
    Returns static configuration and capability information including
    manufacturer details, measurement ranges, accuracy specifications,
    supported protocols, available endpoints, and polling recommendations.
    
    Returns:
        Response: JSON containing device metadata, measurement ranges,
                  capabilities, endpoints, and polling recommendations
    """
    return jsonify({
        "device_id": DEVICE_ID,
        "device_type": "sensor",
        "sensor_type": SENSOR_TYPE,
        "manufacturer": "MockSensors Inc",
        "model": "MS-TH-2024",
        "serial_number": f"MS{random.randint(100000, 999999)}",
        "firmware_version": "2.1.4",
        "supported_protocols": ["http"],
        "data_formats": ["json"],
        "measurement_ranges": {
            "temperature": {
                "min_celsius": -40,
                "max_celsius": 80,
                "accuracy": "±2°C"
            },
            "humidity": {
                "min_percent": 0,
                "max_percent": 100,
                "accuracy": "±5%"
            }
        },
        "endpoints": {
            "current_data": "/api/sensor/data",
            "sensor_status": "/api/sensor/status",
            "device_info": "/api/device/info",
            "health": "/health"
        },
        "polling_recommendations": {
            "minimum_interval_seconds": 5,
            "recommended_interval_seconds": 15,
            "maximum_rate_per_minute": 60
        }
    })


@app.route('/', methods=['GET'])
def root():
    """Root endpoint providing API discovery and documentation.
    
    Returns service metadata and available endpoints for API discovery.
    Does not require authentication.
    
    Returns:
        Response: JSON containing service information, device_id, sensor_type,
                  version, available endpoints, and documentation links
    """
    return jsonify({
        "service": "Mock Generic Sensor API",
        "device_id": DEVICE_ID,
        "sensor_type": SENSOR_TYPE,
        "version": "1.0.0",
        "endpoints": [
            "/health",
            "/api/sensor/data",
            "/api/sensor/status",
            "/api/device/info"
        ],
        "documentation": "https://github.com/microsoft/edge-ai/tree/main/src/500-application/505-akri-rest-http-connector"
    })


if __name__ == '__main__':
    print(f"Starting Mock Generic Sensor API for {DEVICE_ID} ({SENSOR_TYPE})")
    print(f"Server running on port {PORT}")
    app.run(host='0.0.0.0', port=PORT, debug=False)
