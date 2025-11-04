#!/usr/bin/env python3
"""
Mock Weather Station REST API
Simulates a weather station that provides temperature, humidity, and pressure data
"""

import os
import random
import time
from datetime import datetime, timezone
from flask import Flask, jsonify

app = Flask(__name__)

# Configuration from environment variables
PORT = int(os.environ.get('PORT', 8080))
DEVICE_ID = os.environ.get('DEVICE_ID', 'weather-station-001')
LOCATION = os.environ.get('LOCATION', 'Seattle')


def generate_weather_data():
    """Generate realistic simulated weather station data.
    
    Creates randomized weather measurements with realistic variations
    for temperature, humidity, pressure, and weather conditions.
    Temperature ranges from 15-30°C, humidity from 40-90%, and
    pressure from 993-1033 hPa.
    
    Returns:
        dict: Weather data including:
            - timestamp: Current UTC timestamp
            - device_id: Weather station identifier
            - location: Station location
            - weather: Temperature (C/F), humidity, pressure, conditions
            - metadata: Sensor model, firmware, battery, signal strength
    """
    base_temp = 20.0 + random.uniform(-5.0, 10.0)  # 15-30°C
    base_humidity = 60.0 + random.uniform(-20.0, 30.0)  # 40-90%
    base_pressure = 1013.25 + random.uniform(-20.0, 20.0)  # 993-1033 hPa

    return {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "device_id": DEVICE_ID,
        "location": LOCATION,
        "weather": {
            "temperature": {
                "celsius": round(base_temp, 2),
                "fahrenheit": round((base_temp * 9/5) + 32, 2)
            },
            "humidity": {
                "percent": round(max(0, min(100, base_humidity)), 2)
            },
            "pressure": {
                "hpa": round(base_pressure, 2),
                "inhg": round(base_pressure * 0.02953, 2)
            },
            "conditions": random.choice([
                "sunny", "partly_cloudy", "cloudy", "overcast",
                "light_rain", "rain", "foggy", "clear"
            ])
        },
        "metadata": {
            "sensor_model": "WeatherPro 3000",
            "firmware_version": "1.2.3",
            "battery_level": round(random.uniform(85, 100), 1),
            "signal_strength": round(random.uniform(-70, -40), 1),
            "last_calibration": "2025-09-15T10:30:00Z"
        }
    }


@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint for monitoring service availability.
    
    Lightweight endpoint for health monitoring and service discovery.
    Does not require authentication.
    
    Returns:
        Response: JSON containing status, timestamp, device_id,
                  uptime, and location
    """
    return jsonify({
        "status": "healthy",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "device_id": DEVICE_ID,
        "uptime": time.time(),
        "location": LOCATION
    })


@app.route('/api/weather', methods=['GET'])
def get_weather():
    """Get current weather measurements from the station.
    
    Returns real-time weather data including temperature (in both Celsius
    and Fahrenheit), humidity percentage, atmospheric pressure (in hPa
    and inHg), current weather conditions, and sensor metadata.
    
    Returns:
        Response: JSON containing current weather measurements and metadata
    """
    return jsonify(generate_weather_data())


@app.route('/api/weather/history', methods=['GET'])
def get_weather_history():
    """Get historical weather data for the past 24 hours.
    
    Returns simulated hourly weather readings for the last 24 hours.
    Useful for trend analysis and data validation.
    
    Returns:
        Response: JSON containing device_id, location, time period,
                  and array of 24 hourly weather readings
    """
    history = []
    base_time = datetime.now(timezone.utc)

    for i in range(24):
        # Generate data for each hour in the past 24 hours
        timestamp = base_time.replace(hour=i).isoformat()
        data = generate_weather_data()
        data["timestamp"] = timestamp
        history.append(data)

    return jsonify({
        "device_id": DEVICE_ID,
        "location": LOCATION,
        "period": "24_hours",
        "readings": history
    })


@app.route('/api/device/info', methods=['GET'])
def get_device_info():
    """Get comprehensive weather station device information.
    
    Returns static configuration and capability information about the
    weather station including manufacturer details, supported protocols,
    available endpoints, and polling interval recommendations.
    
    Returns:
        Response: JSON containing device metadata, capabilities, endpoints,
                  and recommended polling intervals
    """
    return jsonify({
        "device_id": DEVICE_ID,
        "device_type": "weather_station",
        "location": LOCATION,
        "manufacturer": "MockCorp",
        "model": "WeatherPro 3000",
        "firmware_version": "1.2.3",
        "supported_protocols": ["http", "https"],
        "data_formats": ["json"],
        "endpoints": {
            "current_weather": "/api/weather",
            "weather_history": "/api/weather/history",
            "device_info": "/api/device/info",
            "health": "/health"
        },
        "polling_interval_recommendations": {
            "minimum_seconds": 15,
            "recommended_seconds": 60,
            "maximum_seconds": 300
        }
    })


@app.route('/', methods=['GET'])
def root():
    """Root endpoint providing API discovery and documentation.
    
    Returns service metadata and available endpoints for API discovery.
    Does not require authentication.
    
    Returns:
        Response: JSON containing service information, device_id, location,
                  version, available endpoints, and documentation links
    """
    return jsonify({
        "service": "Mock Weather Station API",
        "device_id": DEVICE_ID,
        "location": LOCATION,
        "version": "1.0.0",
        "endpoints": [
            "/health",
            "/api/weather",
            "/api/weather/history",
            "/api/device/info"
        ],
        "documentation": "https://github.com/microsoft/edge-ai/tree/main/src/500-application/505-akri-rest-http-connector"
    })


if __name__ == '__main__':
    print(f"Starting Mock Weather Station API for {DEVICE_ID} at {LOCATION}")
    print(f"Server running on port {PORT}")
    app.run(host='0.0.0.0', port=PORT, debug=False)
