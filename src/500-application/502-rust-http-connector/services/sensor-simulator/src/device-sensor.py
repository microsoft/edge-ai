"""
device-sensor.py

This Flask application simulates a DHT11/DHT22 sensor device, providing
randomized temperature and humidity readings.
It exposes REST API endpoints to retrieve temperature, humidity, or combined
sensor data, along with a health check endpoint.
"""

import random
from datetime import datetime
from flask import Flask, jsonify

app = Flask(__name__)

# DHT11/DHT22 typical ranges
TEMPERATURE_RANGE_C = (15.0, 35.0)  # Celsius
HUMIDITY_RANGE = (20.0, 90.0)       # Percent


def generate_temperature():
    """
    Generate a random temperature value within the typical DHT11/DHT22
    sensor range.
    """
    return round(random.uniform(*TEMPERATURE_RANGE_C), 1)


def generate_humidity():
    """
    Generate a random humidity value within the typical DHT11/DHT22
    sensor range.
    """
    return round(random.uniform(*HUMIDITY_RANGE), 1)


def celsius_to_fahrenheit(celsius):
    """Convert temperature from Celsius to Fahrenheit."""
    return round((celsius * 9/5) + 32, 1)


def generate_timestamp():
    """Generate a timestamp string in the format YYYY/MM/DD HH:MM:SS."""
    return datetime.now().strftime("%Y/%m/%d %H:%M:%S")


@app.route('/healthcheck', methods=['GET'])
def healthcheck():
    """Health check endpoint to verify sensor service status."""
    return jsonify({
        "status": "OK",
        "version": "1.0",
        "details": {
            "temperature_sensor": "OK",
            "humidity_sensor": "OK"
        }
    })


@app.route('/sensor/temperature', methods=['GET'])
def temperature():
    """
    Endpoint to retrieve randomized temperature data in Celsius and Fahrenheit.
    """
    temp_c = generate_temperature()
    temp_f = celsius_to_fahrenheit(temp_c)
    data = {
        "timestamp": generate_timestamp(),
        "temperature": {
            "celsius": temp_c,
            "fahrenheit": temp_f
        }
    }
    return jsonify(data)


@app.route('/sensor/humidity', methods=['GET'])
def humidity():
    """Endpoint to retrieve randomized humidity data in percent."""
    humidity_value = generate_humidity()
    data = {
        "timestamp": generate_timestamp(),
        "humidity": {
            "percent": humidity_value
        }
    }
    return jsonify(data)


@app.route('/sensor/data', methods=['GET'])
def combined_sensor_data():
    """Endpoint to retrieve combined randomized temperature and humidity data."""
    temp_c = generate_temperature()
    humidity_value = generate_humidity()
    data = {
        "timestamp": generate_timestamp(),
        "temperature": {
            "celsius": temp_c,
            "fahrenheit": celsius_to_fahrenheit(temp_c)
        },
        "humidity": {
            "percent": humidity_value
        }
    }
    return jsonify(data)


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
